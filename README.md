# aria2-resume-signed-url

Resume a huge download (written for a ~49 GiB file) from a host that only hands out
**short-lived signed URLs** (for example S3-style links with `X-Amz-Expires=300`),
on Windows, without losing progress when the link expires.

## How it works

- `aria2c -c` resumes from a `.aria2` progress map saved next to the file.
- When the link expires, aria2 exits with HTTP 403 (XML error). `download.bat`
  catches that and asks for a fresh link, then resumes from where it stopped.
- Each new link is Range-tested first. You want `HTTP/1.1 206` and a
  `Content-Range: bytes 0-0/<total>` line.

## Requirements

- Windows 10/11 (`curl.exe` is built in)
- aria2: `winget install aria2.aria2` (open a new terminal afterward)
- Free disk space larger than the file

## Usage

1. Edit `DIR` and `NAME` at the top of `download.bat`. Keep them identical on every run.
2. Generate one link in the panel and run its Range test. Note the total size and the ETag.
3. **Pre-size the file** so NTFS zero-fill does not eat the link's lifetime:
   ```powershell
   .\prealloc.ps1 -Path "C:\Users\you\Downloads\Server\bigfile.tar.gz" -Size 53027644164
   ```
   Wait for `Done`. No link is needed for this step.
4. Double-click `download.bat`. At the prompt, generate a new link, right-click to paste, press Enter.
5. When aria2 stops with 403s, generate another link and paste it. Repeat until `Download complete.`
6. Verify the size equals the total from `Content-Range`:
   ```powershell
   (Get-Item "C:\Users\you\Downloads\Server\bigfile.tar.gz").Length
   ```

## Rules

- Never delete the `.aria2` file. Without it aria2 cannot tell which pieces are done.
- Do not change `DIR` or `NAME` between runs.
- Compare the ETag and total size on every new link. If either changes, the file
  changed on the server. Do not resume into the same partial file.
- If the host rate-limits you, lower `-x 16 -s 16` to `-x 8 -s 8`.
- Signed URLs contain credentials. Do not commit or share live links.

## Files

| File | Purpose |
|---|---|
| `download.bat` | Prompt for a URL, Range-test it, run aria2, loop on failure |
| `prealloc.ps1` | Pre-size the target file to avoid the NTFS zero-fill stall |
