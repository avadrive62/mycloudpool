# CloudPool on Blitz.cloud

One password-protected website for the existing rclone Google Drive union
named **pool**. Your files stay in Google Drive. The server keeps the
configuration and presents the file manager to browsers on Windows and Android.

This package uses rclone 1.75.2, rclone-web 1.1.11 and Caddy 2.11.7.
The web UI is adapted so downloads, including folder ZIP downloads, use the
same HTTPS address. The file list also keeps filenames and actions visible on
phone screens. It does not require a filesystem mount or WinFsp on the server.

## 1. Your existing setup

Your Blitz.cloud account is on the Free plan at `avadrive62.blitz.cloud`.
Use your existing GitHub repository, `avadrive62/mycloudpool`.
No database, paid domain, or Pro trial is needed.

## 2. Put this package in a GitHub repository

1. Extract the downloaded ZIP on Windows (right-click -> Extract All).
2. Open https://github.com/avadrive62/mycloudpool.
3. Select **Add file -> Upload files**.
4. Upload the eight extracted files, including `Dockerfile`, `start.sh`,
   `Caddyfile`, `waiting.Caddyfile`, `patch-gui.mjs`, `CLOUDPOOL-SETUP.md`,
   `.dockerignore` and `.gitignore`.
5. Put the files directly at the repository's top level, beside your existing
   webpage files. Do not upload the ZIP or its containing folder.
6. Select **Commit changes**. Keep your existing `index.html`, privacy page and
   README. None of those files is replaced by this package.

The package contains no Google credentials and is safe to publish.
**Never upload your `rclone.conf`, Google OAuth JSON, passwords, or Base64
configuration to GitHub.** Those belong only in the private app settings below.

## 3. Create the Blitz.cloud app

1. In Blitz.cloud, click **Host something new**.
2. Choose **My own code**.
3. Paste your repository URL: `https://github.com/avadrive62/mycloudpool`.
   If the wizard was already open before the files were uploaded, return to
   the source step and select the repository again so detection sees the code.
4. Check that **What we found** identifies the root `Dockerfile`. Continue
   through the settings and name the app **pool** when asked.
5. Keep the root `Dockerfile`, port **8080**, and persistent/kept folder **/data**.
   `VOLUME /data` and `EXPOSE 8080` are already declared in the Dockerfile.
6. Add the three private environment settings below. You can enter them on
   the wizard's Settings screen using **Add another**, or afterwards on the
   app's Environment tab. Then finish the wizard to build the app.

The first build downloads the required software. If it starts before you add
the settings, its webpage says **CloudPool is waiting for configuration**.

## 4. Add three private environment settings

On the wizard's **Settings** screen, select **Add another** for each entry.
For an existing app, open its **Environment** tab instead.

| Name | Value |
| --- | --- |
| `CLOUDPOOL_USER` | Your login name, for example `aghvan` |
| `CLOUDPOOL_PASSWORD` | A unique password of at least 16 characters, using Latin letters, digits and symbols |
| `CLOUDPOOL_CONFIG_B64` | Your existing configuration, copied with the PowerShell command below |

Use only letters, digits, dots, underscores and hyphens in the login name.
Avoid leading or trailing spaces in either field.

To copy the configuration value, open PowerShell on your Windows PC and run
this one command:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $env:APPDATA "rclone\rclone.conf"))) | Set-Clipboard
```

Nothing needs to be printed. The value is now on the clipboard.
Paste it into the private **Value** field for `CLOUDPOOL_CONFIG_B64` in Blitz.cloud.
Base64 is an encoding, not encryption: treat this value as a password and
paste it only into your app's private Environment settings.

Save the settings and click **Restart**. Keep **/data** in the app's kept folders.
This package expects the unencrypted rclone.conf you already use, including
`g01`, `g02` and the union named `pool`.

## 5. Use the website

1. Open the app's actual HTTPS address shown by Blitz.cloud.
2. In the browser's login prompt, enter `CLOUDPOOL_USER` and `CLOUDPOOL_PASSWORD`.
3. The rclone web interface should connect automatically. If it asks again,
   enter the same username and password and select **Connect**.
4. Choose **Remotes -> pool**.
5. Use **Upload**, file download buttons, and the folder controls.

Bookmark the app's main address. Open that same address on another PC or on
Android and sign in with the same website login. Those devices do not need
rclone, RSAF, WinFsp, or a copy of the configuration for browser access.
Your Windows PC may be switched off once its own pending uploads have finished.

Only use this administrative website on devices you trust. The rclone interface
also includes settings for the server and the connected accounts.

## Adding more Google accounts later

Configure the additional drives and update `pool` on Windows as before.
Copy the updated configuration using the same PowerShell command, replace
`CLOUDPOOL_CONFIG_B64` in Blitz.cloud, and restart the app.
Every device using the website will then see the updated pool.

The same unchanged Base64 value is only an import seed. On normal restarts,
the app preserves the configuration in `/data/config/rclone.conf`, including
token refreshes and remote changes made on the server. Changing the seed
imports the new file and keeps the previous server configuration as a private
`.previous` backup.

## Free-plan behavior and troubleshooting

- Blitz.cloud's published Free plan sleeps after 30 minutes with no browser
  visitors and wakes on a browser visit. It currently limits outgoing traffic
  to 50 Mbit/s per app, with no monthly traffic quota.
- The host's disk space is separate from the Google Drive account quotas.
  Large transfers still depend on host limits, browser resources and available
  space in the individual destination Google account.
- If the waiting page remains, confirm the three variable names and values,
  restart the app, and check its Logs. Never paste the secret values into chat.
- If a build fails, share the error text from the build log.
- If Google returns an OAuth error such as `disabled_client`, the Google
  credentials need attention; changing hosting cannot restore a disabled client.
- Browser access depends on this app running. Keep your original Windows
  configuration as a backup and as an independent access method.

## Software and upstream sources

- rclone: https://rclone.org/ and https://github.com/rclone/rclone (MIT).
- rclone-web: https://github.com/rclone/rclone-web (MIT; its license is copied
  into the built image).
- Caddy: https://github.com/caddyserver/caddy (Apache-2.0).
- Blitz deployment: https://blitz.cloud/docs/deploy-from-github/
- Blitz settings: https://blitz.cloud/docs/settings-and-files/
- Blitz current limits: https://blitz.cloud/docs/limits/

The application source and container versions are pinned. The package does not
contain your credentials and has not been deployed to your Blitz.cloud account yet.

Local checks passed for the frontend build, password protection, browser file
upload and download, folder ZIP downloads, configuration persistence and an
Android-sized browser viewport. These checks used local test remotes, not your
private Google accounts. The actual Docker image build and Blitz.cloud deployment
still need to run on your host.
