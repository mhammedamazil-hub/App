# Make the APK downloadable — 3 clicks, one time only

You only need to do this once. After that, every update to the app
automatically builds a fresh APK that anyone can download for free.

## What to do (it takes 30 seconds)

1. **Click this link** — it opens GitHub with the build recipe already filled in:

   <https://github.com/mhammedamazil-hub/App/new/arena/01a008ff-app?filename=.github/workflows/build-apk.yml&value=name%3A%20build-android-apk%0A%0A%23%20Builds%20the%20TaskFlow%20Android%20APK%20and%20publishes%20it%20as%20a%20GitHub%20Release%0A%23%20%28rolling%20tag%20%60latest%60%29%20so%20anyone%20can%20download%20and%20install%20it%3A%0A%23%20https%3A%2F%2Fgithub.com%2Fmhammedamazil-hub%2FApp%2Freleases%2Flatest%0A%23%0A%23%20Enable%20this%20workflow%20by%20copying%20this%20file%20to%20.github%2Fworkflows%2F%20in%20the%0A%23%20repository%20%28GitHub%20requires%20workflow%20files%20to%20be%20added%20by%20a%20human%20account%29.%0A%0Aon%3A%0A%20%20push%3A%0A%20%20%20%20branches%3A%20%5B%22main%22%2C%20%22arena%2F01a008ff-app%22%5D%0A%20%20%20%20paths-ignore%3A%0A%20%20%20%20%20%20-%20%22ci-logs%2F%2A%2A%22%0A%20%20%20%20%20%20-%20%22README.md%22%0A%20%20%20%20%20%20-%20%22%2A.md%22%0A%20%20%20%20%20%20-%20%22tool%2F%2A%2A%22%0A%20%20%20%20%20%20-%20%22docs%2F%2A%2A%22%0A%20%20workflow_dispatch%3A%0A%0Apermissions%3A%0A%20%20contents%3A%20write%0A%0Aconcurrency%3A%0A%20%20group%3A%20taskflow-apk%0A%20%20cancel-in-progress%3A%20true%0A%0Ajobs%3A%0A%20%20build%3A%0A%20%20%20%20runs-on%3A%20ubuntu-latest%0A%20%20%20%20steps%3A%0A%20%20%20%20%20%20-%20name%3A%20Checkout%20app%20code%0A%20%20%20%20%20%20%20%20uses%3A%20actions%2Fcheckout%40v4%0A%20%20%20%20%20%20%20%20with%3A%0A%20%20%20%20%20%20%20%20%20%20ref%3A%20arena%2F01a008ff-app%0A%0A%20%20%20%20%20%20-%20name%3A%20Set%20up%20Flutter%0A%20%20%20%20%20%20%20%20uses%3A%20subosito%2Fflutter-action%40v2%0A%20%20%20%20%20%20%20%20with%3A%0A%20%20%20%20%20%20%20%20%20%20channel%3A%20stable%0A%20%20%20%20%20%20%20%20%20%20flutter-version%3A%20%223.35.7%22%0A%20%20%20%20%20%20%20%20%20%20cache%3A%20true%0A%0A%20%20%20%20%20%20-%20name%3A%20Prepare%20Android%20toolchain%0A%20%20%20%20%20%20%20%20run%3A%20%7C%0A%20%20%20%20%20%20%20%20%20%20flutter%20create%20.%20--platforms%3Dandroid%20--project-name%20taskflow%20--org%20com.taskflow%0A%20%20%20%20%20%20%20%20%20%20yes%20%7C%20flutter%20doctor%20--android-licenses%20%7C%7C%20true%0A%0A%20%20%20%20%20%20-%20name%3A%20Test%20and%20build%20APK%0A%20%20%20%20%20%20%20%20run%3A%20%7C%0A%20%20%20%20%20%20%20%20%20%20mkdir%20-p%20ci-logs%0A%20%20%20%20%20%20%20%20%20%20set%20-o%20pipefail%0A%20%20%20%20%20%20%20%20%20%20flutter%20pub%20get%202%3E%261%20%7C%20tee%20ci-logs%2Flatest-build.log%0A%20%20%20%20%20%20%20%20%20%20flutter%20test%202%3E%261%20%7C%20tee%20-a%20ci-logs%2Flatest-build.log%0A%20%20%20%20%20%20%20%20%20%20flutter%20build%20apk%20--release%202%3E%261%20%7C%20tee%20-a%20ci-logs%2Flatest-build.log%0A%0A%20%20%20%20%20%20-%20name%3A%20Publish%20release%0A%20%20%20%20%20%20%20%20env%3A%0A%20%20%20%20%20%20%20%20%20%20GH_TOKEN%3A%20%24%7B%7B%20github.token%20%7D%7D%0A%20%20%20%20%20%20%20%20run%3A%20%7C%0A%20%20%20%20%20%20%20%20%20%20cp%20build%2Fapp%2Foutputs%2Fflutter-apk%2Fapp-release.apk%20taskflow.apk%0A%20%20%20%20%20%20%20%20%20%20gh%20release%20delete%20latest%20--yes%20--cleanup-tag%20%7C%7C%20true%0A%20%20%20%20%20%20%20%20%20%20gh%20release%20create%20latest%20taskflow.apk%20%5C%0A%20%20%20%20%20%20%20%20%20%20%20%20--title%20%22TaskFlow%20%E2%80%94%20Android%20APK%22%20%5C%0A%20%20%20%20%20%20%20%20%20%20%20%20--notes%20%22Install%3A%20download%20taskflow.apk%2C%20open%20it%20on%20your%20Android%20phone%20and%20allow%20installs%20from%20unknown%20sources.%20Built%20from%20commit%20%24%7B%7B%20github.sha%20%7D%7D.%22%0A%20%20%20%20%20%20%20%20%20%20echo%20%22Download%20page%3A%20https%3A%2F%2Fgithub.com%2F%24%7B%7B%20github.repository%20%7D%7D%2Freleases%2Flatest%22%0A%20%20%20%20%20%20%20%20%20%20echo%20%22Direct%20APK%3A%20%20%20%20https%3A%2F%2Fgithub.com%2F%24%7B%7B%20github.repository%20%7D%7D%2Freleases%2Flatest%2Fdownload%2Ftaskflow.apk%22%0A%0A%20%20%20%20%20%20-%20name%3A%20Attach%20build%20log%20on%20failure%0A%20%20%20%20%20%20%20%20if%3A%20failure%28%29%0A%20%20%20%20%20%20%20%20run%3A%20%7C%0A%20%20%20%20%20%20%20%20%20%20git%20config%20user.name%20%22taskflow-ci%22%0A%20%20%20%20%20%20%20%20%20%20git%20config%20user.email%20%22ci%40taskflow.local%22%0A%20%20%20%20%20%20%20%20%20%20git%20add%20ci-logs%2Flatest-build.log%0A%20%20%20%20%20%20%20%20%20%20git%20commit%20-m%20%22ci%3A%20build%20log%22%20%7C%7C%20true%0A%20%20%20%20%20%20%20%20%20%20git%20push%20origin%20HEAD%3Aarena%2F01a008ff-app%0A>

2. On the page that opens, click the green **"Commit changes…"** button,
   then **"Commit changes"** again in the little popup. That's it.

3. Wait about 10 minutes while GitHub builds your app. Then anyone
   (including you) can download the app from:

   **https://github.com/mhammedamazil-hub/App/releases/latest**

   Direct APK link (once built):

   **https://github.com/mhammedamazil-hub/App/releases/latest/download/taskflow.apk**

## Manual way (only if the link above doesn't open)

1. Go to your repo → **Add file** → **Create new file**.
2. Name the file exactly: `.github/workflows/build-apk.yml`
3. Copy everything from
   [`tool/build-apk-workflow.yml`](https://github.com/mhammedamazil-hub/App/blob/arena/01a008ff-app/tool/build-apk-workflow.yml)
   and paste it in.
4. Click **"Commit changes…"** → **"Commit changes"**.

## Installing on a phone

Download `taskflow.apk`, open it on an Android phone, and allow
"install from unknown sources" when Android asks. Done — TaskFlow is
installed like any app.
