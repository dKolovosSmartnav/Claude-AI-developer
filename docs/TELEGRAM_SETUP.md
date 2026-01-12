# Telegram Notifications Setup

Get instant alerts on your phone when Claude needs your attention.

## Step 1: Create a Telegram Bot

1. Open **Telegram** on your phone
2. Search for **@BotFather** and open it
3. Send `/newbot`
4. Enter a **name** for your bot (e.g., `Fotios Claude Alerts`)
5. Enter a **username** for your bot (must end in `bot`, e.g., `fotios_claude_bot`)
6. BotFather will send you a message with your **token** - copy it

   ```
   Use this token to access the HTTP API:
   7123456789:AAHk5JxxxxxxxxxxxxxxxxxxxxxxxxxYYY
   ```

## Step 2: Start a Chat with Your Bot

1. Click the link BotFather gave you (t.me/your_bot_username)
   - Or search for your bot's username in Telegram
2. Press **Start** or send `/start`
3. **Important:** Send one more message (e.g., type "hello" and send)
   - This is required for the next step to work

## Step 3: Get Your Chat ID

1. Open this URL in your browser (replace `<TOKEN>` with your actual token):

   ```
   https://api.telegram.org/bot<TOKEN>/getUpdates
   ```

2. You'll see JSON text. Look for:

   ```json
   "chat":{"id":123456789,"first_name":"Your Name"...}
   ```

3. The number after `"id":` is your **Chat ID** (e.g., `123456789`)

## Step 4: Configure in Settings

1. Go to your **Dashboard** (`https://YOUR_IP:9453`)
2. Click the **⚙️** button (top right, near Logout)
3. Enter your **Bot Token**
4. Enter your **Chat ID**
5. Select which notifications you want:
   - ✅ Ticket completed
   - ⏳ Awaiting input (recommended)
   - ❌ Ticket failed (recommended)
   - ⚠️ Watchdog alert (recommended)
6. Click **Test Notification**
7. Check your Telegram - you should receive a test message
8. If successful, click **Save Settings**

## What You'll Receive

| Event | When |
|-------|------|
| ⏳ **Awaiting Input** | Claude finished a task and needs your review or response |
| ❌ **Task Failed** | Something went wrong during execution |
| ⚠️ **Watchdog Alert** | A ticket appears stuck (repeated errors, no progress) |

## Example Notification

```
⏳ Task Completed - Awaiting Review

📁 Project: MyWebsite
🎫 Ticket: WEB-0042

Add user authentication to the login page
```

## Troubleshooting

### "getUpdates shows empty result"
- Make sure you sent `/start` AND one more message to your bot
- Wait a few seconds and refresh the page

### "Test notification not received"
- Double-check your Bot Token (no extra spaces)
- Double-check your Chat ID (numbers only)
- Make sure you started a chat with your bot

### "Chat ID not found in getUpdates"
- Send another message to your bot
- Refresh the getUpdates URL

## Notes

- Notifications are sent instantly when ticket status changes
- Settings are saved in `/etc/fotios-claude/system.conf`
- The daemon restarts automatically when you save settings
- You can disable notifications anytime from the Settings panel
