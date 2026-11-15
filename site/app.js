/* The file vault is independent of each upstream app's own save/export behavior. */
const status = document.querySelector('#status');
const vaultStatus = document.querySelector('#vault-status');
const input = document.querySelector('#file-input');
const list = document.querySelector('#files');
const cards = [...document.querySelectorAll('a.card')];
let registration;
let activeRequest = null;

function message(text) { status.textContent = text; }
function setBusy(busy) {
  document.querySelectorAll('.offline-controls button').forEach(button => { button.disabled = busy; });
}
async function updateBadges() {
  const apps = await dbRequest('apps', 'readonly', store => store.getAll());
  for (const card of cards) {
    const id = card.getAttribute('href').replace(/\/$/, '');
    const saved = apps.find(item => item.id === id);
    const container = card.parentElement;
    container.querySelector('.badge').textContent = saved ? `Offline copy saved (v${saved.version})` : 'Not saved offline';
    container.querySelector('.save-offline').textContent = saved ? 'Update offline' : 'Save offline';
    container.querySelector('.remove-offline').hidden = !saved;
  }
}
async function changeOffline(app, type) {
  if (!registration || !registration.active || activeRequest) return;
  try {
    if (type === 'DOWNLOAD_APP' && navigator.storage?.persist) await navigator.storage.persist().catch(() => false);
    const requestId = `${Date.now()}-${Math.random()}`;
    activeRequest = requestId;
    setBusy(true);
    message(type === 'DOWNLOAD_APP' ? `Downloading ${app} for offline use…` : `Removing offline copy of ${app}…`);
    registration.active.postMessage({ type, app, requestId });
  } catch (error) { activeRequest = null; setBusy(false); message(`Offline setup failed: ${error.message}`); }
}
for (const card of cards) {
  const app = card.getAttribute('href').replace(/\/$/, '');
  const wrapper = document.createElement('div'); wrapper.className = 'app-item';
  card.before(wrapper); wrapper.append(card);
  const badge = document.createElement('span'); badge.className = 'badge'; badge.textContent = 'Checking offline status…';
  const controls = document.createElement('div'); controls.className = 'offline-controls';
  const save = document.createElement('button'); save.type = 'button'; save.className = 'save-offline'; save.textContent = 'Save offline'; save.disabled = true;
  const remove = document.createElement('button'); remove.type = 'button'; remove.className = 'remove-offline'; remove.textContent = 'Remove'; remove.hidden = true; remove.disabled = true;
  save.setAttribute('aria-label', `Save ${app} for offline use`);
  remove.setAttribute('aria-label', `Remove offline copy of ${app}`);
  save.addEventListener('click', () => changeOffline(app, 'DOWNLOAD_APP'));
  remove.addEventListener('click', () => changeOffline(app, 'REMOVE_APP'));
  controls.append(save, remove); wrapper.append(badge, controls);
}
async function setupOffline() {
  try {
    if (!('serviceWorker' in navigator) || !('indexedDB' in window)) throw new Error('Your browser does not support service workers and IndexedDB.');
    navigator.serviceWorker.addEventListener('message', async event => {
      const data = event.data || {};
      if (data.requestId !== activeRequest) return;
      if (data.status === 'progress') { message(`Saving ${data.app}: ${data.count} of ${data.total} files…`); return; }
      activeRequest = null; setBusy(false);
      if (data.status === 'error') message(`Could not save ${data.app}: ${data.message}. Check your connection and available storage.`);
      else message(data.status === 'ready' ? `${data.app} is saved for offline use. Test it in airplane mode.` : `Offline copy of ${data.app} removed.`);
      try { await updateBadges(); } catch (error) { message(`Could not read offline status: ${error.message}`); }
    });
    registration = await navigator.serviceWorker.register('./sw.js');
    await navigator.serviceWorker.ready;
    // ready may resolve an existing registration while the new worker activates.
    registration = await navigator.serviceWorker.getRegistration('./');
    await updateBadges();
    setBusy(false);
    message('Offline support is ready. Save individual apps while online.');
  } catch (error) {
    message(`Offline support unavailable: ${error.message}`);
    document.querySelectorAll('.badge').forEach(badge => { badge.textContent = 'Offline unavailable'; });
  }
}
setupOffline();

let installPrompt;
const installButton = document.querySelector('#install');
window.addEventListener('beforeinstallprompt', event => { event.preventDefault(); installPrompt = event; installButton.hidden = false; });
installButton.addEventListener('click', async () => { if (!installPrompt) return; await installPrompt.prompt(); installPrompt = null; installButton.hidden = true; });
window.addEventListener('appinstalled', () => { installButton.hidden = true; });

function formatSize(bytes) { return bytes < 1024 * 1024 ? `${Math.ceil(bytes / 1024)} KB` : `${(bytes / 1024 / 1024).toFixed(1)} MB`; }
async function showFiles() {
  const files = await dbRequest('files', 'readonly', store => store.getAll());
  list.replaceChildren();
  if (!files.length) { const empty = document.createElement('li'); empty.textContent = 'No files stored yet.'; list.append(empty); return; }
  for (const file of files) {
    const item = document.createElement('li');
    const label = document.createElement('span'); label.textContent = `${file.name} (${formatSize(file.blob.size)})`;
    const download = document.createElement('button'); download.textContent = 'Download';
    download.addEventListener('click', () => {
      const url = URL.createObjectURL(file.blob); const link = document.createElement('a');
      link.href = url; link.download = file.name; link.click(); setTimeout(() => URL.revokeObjectURL(url), 60000);
    });
    const remove = document.createElement('button'); remove.textContent = 'Delete';
    remove.setAttribute('aria-label', `Delete ${file.name} from local vault`);
    remove.addEventListener('click', async () => {
      if (!confirm(`Delete the local copy of ${file.name}?`)) return;
      try { await dbRequest('files', 'readwrite', store => store.delete(file.id)); await showFiles(); vaultStatus.textContent = 'Local copy deleted.'; }
      catch (error) { vaultStatus.textContent = `Could not delete file: ${error.message}`; }
    });
    item.append(label, download, remove); list.append(item);
  }
}
input.addEventListener('change', async () => {
  try {
    if (navigator.storage?.persist) await navigator.storage.persist().catch(() => false);
    for (const file of input.files) await dbRequest('files', 'readwrite', store => store.add({ name: file.name, blob: file, savedAt: Date.now() }));
    vaultStatus.textContent = 'Files stored on this device. Keep a separate backup.';
  } catch (error) { vaultStatus.textContent = `Could not store all files: ${error.message}. Check available storage.`; }
  finally { input.value = ''; try { await showFiles(); } catch (_) {} }
});
showFiles().catch(error => { input.disabled = true; vaultStatus.textContent = `File vault unavailable: ${error.message}`; });
