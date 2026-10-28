# Paylocity Timesheet Fix

Scripts for Windows and Mac that stop Paylocity from logging you out when you open Timesheets, by allowing Paylocity pop-ups and redirects in Google Chrome and Microsoft Edge.

## The problem

Paylocity opens Time & Labor (Timesheets) in a separate session. When the browser blocks that pop-up or redirect, Paylocity treats you as logged out and sends you back to the login page.

## The fix

Both scripts set the browser policy **PopupsAllowedForUrls** to `[*.]paylocity.com`, which covers every Paylocity site, including `webtime2.paylocity.com`. Each script checks first and only makes changes when they're needed, so it's safe to run more than once.

## Windows

**File:** `Allow-PaylocityPopups.ps1`

1. Click **Start**, type **PowerShell**, right-click it, and choose **Run as administrator**.
2. Go to the folder with the script and run:

   ```powershell
   .\Allow-PaylocityPopups.ps1
   ```

   If script execution is blocked, run this instead:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\Allow-PaylocityPopups.ps1
   ```

3. Follow the message at the end:
   - **Green** means the setting was already in place and nothing more is needed.
   - **Red** means the setting was added. Restart the browser, or open `chrome://policy` (`edge://policy` for Edge) and click **Reload policies**.

The script applies to all users on the PC. It adds to any existing pop-up allow list instead of replacing it.

## Mac

**File:** `allow-paylocity-popups.sh`

1. Open **Terminal** and run:

   ```bash
   bash ~/Downloads/allow-paylocity-popups.sh
   ```

   Change the path if you saved the script somewhere else.

2. Follow the message at the end:
   - **Green** means the setting was already in place and nothing more is needed.
   - **Red** means a profile named **Allow Paylocity Pop-ups** was created. To finish:
     1. Open **System Settings** and search for **Profiles**.
     2. Double-click **Allow Paylocity Pop-ups**, click **Install**, and enter your Mac password.
     3. Restart the browser, or open `chrome://policy` (`edge://policy` for Edge) and click **Reload policies**.

macOS requires a person to approve configuration profiles, so the last step can't be scripted. No `sudo` is needed.

## Checking that it worked

Open `chrome://policy` (or `edge://policy`) and look for **PopupsAllowedForUrls** with the value `[*.]paylocity.com` and a status of **OK**.

The browser will also show **"Managed by your organization"** in its menu and settings. This is expected whenever a browser policy is set.

## Managed devices

If your computers are managed with Group Policy, Intune, Jamf, or a similar tool, set **Allow pop-ups on these sites** to `[*.]paylocity.com` there instead. That applies the fix automatically, including on new machines.

## Removing the fix

- **Windows:** In Registry Editor, open `HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome\PopupsAllowedForUrls` (and `...\Microsoft\Edge\PopupsAllowedForUrls`) and delete the entry for `[*.]paylocity.com`.
- **Mac:** In **System Settings > Profiles**, select **Allow Paylocity Pop-ups** and remove it.
