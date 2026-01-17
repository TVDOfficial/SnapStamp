# 📸 SnapStamp

A sleek PowerShell tool that stamps your photos with the original date and time from EXIF metadata. Perfect for organizing photos, creating photo logs, or adding timestamps to event pictures!

![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue?logo=powershell)
![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows)
![License](https://img.shields.io/badge/License-MIT-green)

---

## ✨ Features

- 🖼️ **Batch Processing** - Process entire folders of photos at once
- 📅 **Smart Date Detection** - Reads EXIF metadata to get the *actual* photo date
- 🎨 **Modern Dark UI** - Clean, professional interface with live preview
- 📊 **Progress Tracking** - Real-time progress bar with file count and percentage
- 🗂️ **Multiple Formats** - Supports JPG, PNG, BMP, GIF, TIFF, HEIC, and HEIF
- 💾 **Non-Destructive** - Saves stamped photos to a `stamped` subfolder (originals untouched)
- 🔍 **Modern Folder Picker** - Uses the standard Windows Explorer-style folder browser

---

## 📸 Screenshot

```
<img width="984" height="770" alt="2026-01-17 11_26_17-SnapStamp" src="https://github.com/user-attachments/assets/8ff54f8b-060c-4dc8-8695-b5cf73bc41bd" />


┌─────────────────────────────────────────────────────────────┐
│  SnapStamp                                                  │
│  Stamp your photos with the original date and time          │
├─────────────────────────────────────────────────────────────┤
│  SELECT FOLDER                                              │
│  ┌─────────────────────────────────┐ [Browse] [Start]       │
│  │ C:\Users\Photos\Vacation        │                        │
│  └─────────────────────────────────┘                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                    [ Live Preview ]                         │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  CURRENT FILE: IMG_2024.jpg                                 │
│  Date: 14:32:15 25/12/2024 (EXIF)                          │
│  ████████████████████░░░░░░░░░░  15 / 20     75%           │
└─────────────────────────────────────────────────────────────┘
```

---

## 🚀 Quick Start

### Option 1: Double-Click Run
1. Right-click `SnapStamp.ps1`
2. Select **"Run with PowerShell"**

### Option 2: Command Line
```powershell
powershell -ExecutionPolicy Bypass -File .\SnapStamp.ps1
```

### Option 3: From PowerShell
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\SnapStamp.ps1
```

---

## 📖 How to Use

1. **Launch** the script using one of the methods above
2. **Click Browse** to select a folder containing your photos
3. **Click Start** to begin processing
4. **Watch** the live preview as each photo is stamped
5. **Done!** Find your stamped photos in the `stamped` subfolder

---

## 🎯 Timestamp Format

Photos are stamped with the date in the **bottom-right corner**:

```
┌────────────────────────────────┐
│                                │
│        Your Photo              │
│                                │
│          ┌───────────────────┐ │
│          │ 14:32:15 25/12/2024│ │
│          └───────────────────┘ │
└────────────────────────────────┘
       Yellow text on black background
```

**Format:** `HH:mm:ss dd/MM/yyyy`

---

## 📂 Supported Formats

| Format | Extension | Notes |
|--------|-----------|-------|
| JPEG | `.jpg`, `.jpeg` | ✅ Full EXIF support |
| PNG | `.png` | ✅ XMP metadata support |
| HEIC | `.heic`, `.heif` | ✅ iPhone photos (outputs as JPG) |
| TIFF | `.tif`, `.tiff` | ✅ Full EXIF support |
| BMP | `.bmp` | ⚠️ Limited metadata |
| GIF | `.gif` | ⚠️ Limited metadata |

---

## ⚠️ Important Notes

### About EXIF Metadata

SnapStamp reads the **original photo date** from EXIF metadata embedded in the image. However:

- 📱 **Direct from camera/phone** = ✅ Date will be accurate
- 💬 **Shared via WhatsApp/Messenger** = ⚠️ EXIF often stripped
- 📧 **Downloaded from email** = ⚠️ EXIF may be stripped
- 💼 **Shared via Teams/Slack** = ⚠️ EXIF often stripped

If no EXIF data is found, the script falls back to the file creation date and displays a warning. This date may be when you *downloaded* the file, not when the photo was *taken*.

### Output Location

Stamped photos are saved to a `stamped` subfolder within your selected folder:

```
📁 My Photos
├── 📷 photo1.jpg (original)
├── 📷 photo2.jpg (original)
└── 📁 stamped
    ├── 📷 photo1.jpg (with timestamp)
    └── 📷 photo2.jpg (with timestamp)
```

---

## 🔧 Requirements

- **Windows 10** or **Windows 11**
- **PowerShell 5.1** or later (pre-installed on Windows 10/11)
- **HEIC Codec** for HEIC support (usually pre-installed, or get from Microsoft Store)

---

## 🐛 Troubleshooting

### "Execution Policy" Error
Run this command first:
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

### HEIC Files Not Working
Install the HEIF Image Extensions from the Microsoft Store:
[HEIF Image Extensions](https://www.microsoft.com/store/productId/9PMMSR1CGPWG)

### Wrong Dates Showing
If dates appear wrong, the photos likely don't have EXIF metadata. This happens when:
- Photos were shared through messaging apps
- Photos were downloaded from the web
- Photos were screenshot or edited

---

## 📜 License

MIT License - Feel free to use, modify, and distribute!

---

## 🤝 Contributing

Found a bug? Have a feature request? Feel free to open an issue or submit a pull request!

---

<p align="center">
  Made with ❤️ in PowerShell
</p>


