<#
.SYNOPSIS
    SnapStamp - Adds date/time overlay to photos from EXIF metadata.
.DESCRIPTION
    Opens a folder picker, reads photo metadata (EXIF date taken), and stamps each 
    image with the date/time in the bottom-right corner. Supports JPG, PNG, HEIC, etc.
#>

param(
    [switch]$Recurse
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

# Load required assemblies
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# Enable visual styles for modern look
[System.Windows.Forms.Application]::EnableVisualStyles()

# Script-level variables
$script:Folder = $null
$script:OutputDir = $null
$script:CancelRequested = $false
$script:ShellDateTakenIndex = -1
$script:Extensions = @(".jpg", ".jpeg", ".png", ".bmp", ".gif", ".tif", ".tiff", ".heic", ".heif")

# ============================================================================
# COLOR THEME
# ============================================================================
$Theme = @{
    Background      = [System.Drawing.Color]::FromArgb(30, 30, 30)
    Panel           = [System.Drawing.Color]::FromArgb(45, 45, 48)
    Accent          = [System.Drawing.Color]::FromArgb(0, 122, 204)
    AccentHover     = [System.Drawing.Color]::FromArgb(28, 151, 234)
    Text            = [System.Drawing.Color]::FromArgb(241, 241, 241)
    TextDim         = [System.Drawing.Color]::FromArgb(160, 160, 160)
    Success         = [System.Drawing.Color]::FromArgb(78, 201, 176)
    Warning         = [System.Drawing.Color]::FromArgb(255, 204, 0)
    Border          = [System.Drawing.Color]::FromArgb(63, 63, 70)
    InputBg         = [System.Drawing.Color]::FromArgb(37, 37, 38)
}

# ============================================================================
# MAIN FORM
# ============================================================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "SnapStamp"
$form.Width = 1000
$form.Height = 780
$form.StartPosition = "CenterScreen"
$form.MaximizeBox = $false
$form.FormBorderStyle = "FixedSingle"
$form.BackColor = $Theme.Background
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

# ============================================================================
# HEADER PANEL
# ============================================================================
$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Dock = "Top"
$headerPanel.Height = 70
$headerPanel.BackColor = $Theme.Panel

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "SnapStamp"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 18)
$titleLabel.ForeColor = $Theme.Text
$titleLabel.AutoSize = $true
$titleLabel.Location = New-Object System.Drawing.Point(20, 12)

$subtitleLabel = New-Object System.Windows.Forms.Label
$subtitleLabel.Text = "Stamp your photos with the original date and time"
$subtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$subtitleLabel.ForeColor = $Theme.TextDim
$subtitleLabel.AutoSize = $true
$subtitleLabel.Location = New-Object System.Drawing.Point(22, 45)

$headerPanel.Controls.AddRange(@($titleLabel, $subtitleLabel))

# ============================================================================
# CONTROLS PANEL
# ============================================================================
$controlsPanel = New-Object System.Windows.Forms.Panel
$controlsPanel.Dock = "Top"
$controlsPanel.Height = 100
$controlsPanel.BackColor = $Theme.Background
$controlsPanel.Padding = New-Object System.Windows.Forms.Padding(20, 15, 20, 15)

$folderLabel = New-Object System.Windows.Forms.Label
$folderLabel.Text = "SELECT FOLDER"
$folderLabel.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 8)
$folderLabel.ForeColor = $Theme.TextDim
$folderLabel.AutoSize = $true
$folderLabel.Location = New-Object System.Drawing.Point(20, 15)

$folderTextBox = New-Object System.Windows.Forms.TextBox
$folderTextBox.Width = 680
$folderTextBox.Height = 32
$folderTextBox.Location = New-Object System.Drawing.Point(20, 35)
$folderTextBox.ReadOnly = $true
$folderTextBox.BackColor = $Theme.InputBg
$folderTextBox.ForeColor = $Theme.Text
$folderTextBox.BorderStyle = "FixedSingle"
$folderTextBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$folderTextBox.Text = "Click Browse to select a folder..."

$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Text = "Browse..."
$browseButton.Width = 100
$browseButton.Height = 32
$browseButton.Location = New-Object System.Drawing.Point(710, 35)
$browseButton.FlatStyle = "Flat"
$browseButton.BackColor = $Theme.Accent
$browseButton.ForeColor = $Theme.Text
$browseButton.Cursor = "Hand"
$browseButton.FlatAppearance.BorderSize = 0

$startButton = New-Object System.Windows.Forms.Button
$startButton.Text = "Start"
$startButton.Width = 80
$startButton.Height = 32
$startButton.Location = New-Object System.Drawing.Point(820, 35)
$startButton.FlatStyle = "Flat"
$startButton.BackColor = $Theme.Success
$startButton.ForeColor = $Theme.Background
$startButton.Cursor = "Hand"
$startButton.Enabled = $false
$startButton.FlatAppearance.BorderSize = 0

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Text = "Cancel"
$cancelButton.Width = 80
$cancelButton.Height = 32
$cancelButton.Location = New-Object System.Drawing.Point(910, 35)
$cancelButton.FlatStyle = "Flat"
$cancelButton.BackColor = $Theme.Panel
$cancelButton.ForeColor = $Theme.TextDim
$cancelButton.Cursor = "Hand"
$cancelButton.Enabled = $false
$cancelButton.FlatAppearance.BorderSize = 1
$cancelButton.FlatAppearance.BorderColor = $Theme.Border

$controlsPanel.Controls.AddRange(@($folderLabel, $folderTextBox, $browseButton, $startButton, $cancelButton))

# ============================================================================
# PREVIEW PANEL
# ============================================================================
$previewContainer = New-Object System.Windows.Forms.Panel
$previewContainer.Dock = "Fill"
$previewContainer.Padding = New-Object System.Windows.Forms.Padding(20, 10, 20, 10)
$previewContainer.BackColor = $Theme.Background

$previewLabel = New-Object System.Windows.Forms.Label
$previewLabel.Text = "PREVIEW"
$previewLabel.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 8)
$previewLabel.ForeColor = $Theme.TextDim
$previewLabel.AutoSize = $true
$previewLabel.Location = New-Object System.Drawing.Point(0, 0)

$pictureBox = New-Object System.Windows.Forms.PictureBox
$pictureBox.Location = New-Object System.Drawing.Point(0, 22)
$pictureBox.Size = New-Object System.Drawing.Size(940, 420)
$pictureBox.SizeMode = "Zoom"
$pictureBox.BackColor = $Theme.Panel
$pictureBox.BorderStyle = "None"

$previewContainer.Controls.AddRange(@($previewLabel, $pictureBox))

# ============================================================================
# BOTTOM STATUS PANEL
# ============================================================================
$bottomPanel = New-Object System.Windows.Forms.Panel
$bottomPanel.Dock = "Bottom"
$bottomPanel.Height = 140
$bottomPanel.BackColor = $Theme.Panel
$bottomPanel.Padding = New-Object System.Windows.Forms.Padding(20, 15, 20, 15)

$currentFileLabel = New-Object System.Windows.Forms.Label
$currentFileLabel.Text = "CURRENT FILE"
$currentFileLabel.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 8)
$currentFileLabel.ForeColor = $Theme.TextDim
$currentFileLabel.AutoSize = $true
$currentFileLabel.Location = New-Object System.Drawing.Point(20, 12)

$fileNameLabel = New-Object System.Windows.Forms.Label
$fileNameLabel.Text = "Waiting to start..."
$fileNameLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11)
$fileNameLabel.ForeColor = $Theme.Text
$fileNameLabel.AutoSize = $false
$fileNameLabel.Size = New-Object System.Drawing.Size(600, 25)
$fileNameLabel.Location = New-Object System.Drawing.Point(20, 30)

$dateInfoLabel = New-Object System.Windows.Forms.Label
$dateInfoLabel.Text = ""
$dateInfoLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$dateInfoLabel.ForeColor = $Theme.Warning
$dateInfoLabel.AutoSize = $true
$dateInfoLabel.Location = New-Object System.Drawing.Point(20, 55)

$progressLabel = New-Object System.Windows.Forms.Label
$progressLabel.Text = "PROGRESS"
$progressLabel.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 8)
$progressLabel.ForeColor = $Theme.TextDim
$progressLabel.AutoSize = $true
$progressLabel.Location = New-Object System.Drawing.Point(20, 80)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20, 98)
$progressBar.Size = New-Object System.Drawing.Size(760, 24)
$progressBar.Minimum = 0
$progressBar.Maximum = 100
$progressBar.Value = 0
$progressBar.Style = "Continuous"

$countLabel = New-Object System.Windows.Forms.Label
$countLabel.Text = "0 / 0"
$countLabel.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 12)
$countLabel.ForeColor = $Theme.Text
$countLabel.AutoSize = $true
$countLabel.Location = New-Object System.Drawing.Point(800, 96)

$percentLabel = New-Object System.Windows.Forms.Label
$percentLabel.Text = "0%"
$percentLabel.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 14)
$percentLabel.ForeColor = $Theme.Accent
$percentLabel.AutoSize = $true
$percentLabel.Location = New-Object System.Drawing.Point(900, 94)

$bottomPanel.Controls.AddRange(@(
    $currentFileLabel, $fileNameLabel, $dateInfoLabel,
    $progressLabel, $progressBar, $countLabel, $percentLabel
))

# ============================================================================
# ADD ALL PANELS TO FORM
# ============================================================================
$form.Controls.Add($previewContainer)
$form.Controls.Add($bottomPanel)
$form.Controls.Add($controlsPanel)
$form.Controls.Add($headerPanel)

# ============================================================================
# DATE EXTRACTION FUNCTIONS
# ============================================================================

function Find-ShellDateTakenIndex {
    param([string]$FolderPath)
    
    if ($script:ShellDateTakenIndex -ge 0) {
        return $script:ShellDateTakenIndex
    }
    
    try {
        $shell = New-Object -ComObject Shell.Application
        $folder = $shell.Namespace($FolderPath)
        if ($null -eq $folder) { return -1 }
        
        for ($i = 0; $i -le 350; $i++) {
            $name = $folder.GetDetailsOf($null, $i)
            if ($name -eq "Date taken") {
                $script:ShellDateTakenIndex = $i
                return $i
            }
        }
    } catch { }
    
    return -1
}

function Get-DateFromShell {
    param([System.IO.FileInfo]$File)
    
    $idx = Find-ShellDateTakenIndex -FolderPath $File.Directory.FullName
    if ($idx -lt 0) { return $null }
    
    try {
        $shell = New-Object -ComObject Shell.Application
        $folder = $shell.Namespace($File.Directory.FullName)
        if ($null -eq $folder) { return $null }
        
        $item = $folder.ParseName($File.Name)
        if ($null -eq $item) { return $null }
        
        $dateTaken = $folder.GetDetailsOf($item, $idx)
        if ([string]::IsNullOrWhiteSpace($dateTaken)) { return $null }
        
        # Remove hidden Unicode characters (LRM, RLM, etc.) that Windows sometimes adds
        $cleaned = $dateTaken -replace '[^\x20-\x7E\xA0-\xFF]', ''
        $cleaned = $cleaned.Trim()
        
        if ([string]::IsNullOrWhiteSpace($cleaned)) { return $null }
        
        return [DateTime]::Parse($cleaned, [System.Globalization.CultureInfo]::CurrentCulture)
    } catch {
        return $null
    }
}

function Get-DateFromWic {
    param([System.IO.FileInfo]$File)
    
    $stream = $null
    try {
        $stream = [System.IO.File]::Open(
            $File.FullName,
            [System.IO.FileMode]::Open,
            [System.IO.FileAccess]::Read,
            [System.IO.FileShare]::Read
        )
        
        $decoder = [System.Windows.Media.Imaging.BitmapDecoder]::Create(
            $stream,
            [System.Windows.Media.Imaging.BitmapCreateOptions]::PreservePixelFormat,
            [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
        )
        
        if ($decoder.Frames.Count -eq 0) { return $null }
        
        $frame = $decoder.Frames[0]
        $meta = $frame.Metadata -as [System.Windows.Media.Imaging.BitmapMetadata]
        if ($null -eq $meta) { return $null }
        
        # Try DateTaken property first
        if (-not [string]::IsNullOrWhiteSpace($meta.DateTaken)) {
            try {
                return [DateTime]::Parse($meta.DateTaken, [System.Globalization.CultureInfo]::InvariantCulture)
            } catch { }
        }
        
        # Query various EXIF paths
        $queries = @(
            "/app1/ifd/exif/{ushort=36867}",
            "/app1/ifd/exif/{ushort=36868}",
            "/app1/ifd/{ushort=306}",
            "/ifd/exif/{ushort=36867}",
            "/ifd/exif/{ushort=36868}",
            "/ifd/{ushort=306}",
            "/xmp/exif:DateTimeOriginal",
            "/xmp/xmp:CreateDate",
            "/xmp/photoshop:DateCreated"
        )
        
        foreach ($query in $queries) {
            try {
                $val = $meta.GetQuery($query)
                if ($null -ne $val -and -not [string]::IsNullOrWhiteSpace($val.ToString())) {
                    $raw = $val.ToString().Trim()
                    
                    # Try EXIF format first
                    try {
                        return [DateTime]::ParseExact(
                            $raw,
                            "yyyy:MM:dd HH:mm:ss",
                            [System.Globalization.CultureInfo]::InvariantCulture
                        )
                    } catch { }
                    
                    # Try ISO 8601 format
                    try {
                        return [DateTime]::Parse($raw, [System.Globalization.CultureInfo]::InvariantCulture)
                    } catch { }
                }
            } catch { }
        }
    } catch { }
    finally {
        if ($null -ne $stream) { $stream.Dispose() }
    }
    
    return $null
}

function Get-DateFromSystemDrawing {
    param([System.Drawing.Image]$Image)
    
    if ($null -eq $Image) { return $null }
    
    $exifIds = @(36867, 36868, 306)
    
    foreach ($id in $exifIds) {
        try {
            $prop = $Image.GetPropertyItem($id)
            if ($null -ne $prop -and $null -ne $prop.Value) {
                $raw = [System.Text.Encoding]::ASCII.GetString($prop.Value).Trim([char]0).Trim()
                if (-not [string]::IsNullOrWhiteSpace($raw)) {
                    return [DateTime]::ParseExact(
                        $raw,
                        "yyyy:MM:dd HH:mm:ss",
                        [System.Globalization.CultureInfo]::InvariantCulture
                    )
                }
            }
        } catch { }
    }
    
    return $null
}

function Get-PhotoDateTime {
    param(
        [System.Drawing.Image]$Image,
        [System.IO.FileInfo]$File
    )
    
    $date = $null
    $source = "Unknown"
    
    # Method 1: System.Drawing EXIF (fastest for standard JPGs)
    if ($null -eq $date) {
        $date = Get-DateFromSystemDrawing -Image $Image
        if ($null -ne $date) { $source = "EXIF" }
    }
    
    # Method 2: WIC/WPF metadata (handles HEIC, more EXIF paths, XMP)
    if ($null -eq $date) {
        $date = Get-DateFromWic -File $File
        if ($null -ne $date) { $source = "WIC Metadata" }
    }
    
    # Method 3: Windows Shell (Date taken column)
    if ($null -eq $date) {
        $date = Get-DateFromShell -File $File
        if ($null -ne $date) { $source = "Shell Property" }
    }
    
    # Fallback: File creation time (WARNING: This is often wrong for copied files!)
    if ($null -eq $date) {
        $date = $File.CreationTime
        $source = "File Creation (NO EXIF FOUND - may be wrong!)"
    }
    
    return @{
        Date   = $date
        Source = $source
    }
}

# ============================================================================
# IMAGE HANDLING FUNCTIONS
# ============================================================================

function Get-ImageBitmap {
    param([System.IO.FileInfo]$File)
    
    $ext = $File.Extension.ToLowerInvariant()
    
    # HEIC/HEIF needs WIC decoding
    if ($ext -eq ".heic" -or $ext -eq ".heif") {
        $stream = $null
        $ms = $null
        try {
            $stream = [System.IO.File]::Open(
                $File.FullName,
                [System.IO.FileMode]::Open,
                [System.IO.FileAccess]::Read,
                [System.IO.FileShare]::Read
            )
            
            $decoder = [System.Windows.Media.Imaging.BitmapDecoder]::Create(
                $stream,
                [System.Windows.Media.Imaging.BitmapCreateOptions]::PreservePixelFormat,
                [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
            )
            
            $frame = $decoder.Frames[0]
            $encoder = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
            $encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($frame))
            
            $ms = New-Object System.IO.MemoryStream
            $encoder.Save($ms)
            $ms.Position = 0
            
            $temp = New-Object System.Drawing.Bitmap($ms)
            $bitmap = New-Object System.Drawing.Bitmap($temp)
            $temp.Dispose()
            
            return $bitmap
        } finally {
            if ($null -ne $ms) { $ms.Dispose() }
            if ($null -ne $stream) { $stream.Dispose() }
        }
    }
    
    # Standard formats
    return [System.Drawing.Image]::FromFile($File.FullName)
}

function Get-OutputFormat {
    param([string]$Extension)
    
    switch ($Extension.ToLowerInvariant()) {
        ".jpg"  { return [System.Drawing.Imaging.ImageFormat]::Jpeg }
        ".jpeg" { return [System.Drawing.Imaging.ImageFormat]::Jpeg }
        ".png"  { return [System.Drawing.Imaging.ImageFormat]::Png }
        ".bmp"  { return [System.Drawing.Imaging.ImageFormat]::Bmp }
        ".gif"  { return [System.Drawing.Imaging.ImageFormat]::Gif }
        ".tif"  { return [System.Drawing.Imaging.ImageFormat]::Tiff }
        ".tiff" { return [System.Drawing.Imaging.ImageFormat]::Tiff }
        ".heic" { return [System.Drawing.Imaging.ImageFormat]::Jpeg }
        ".heif" { return [System.Drawing.Imaging.ImageFormat]::Jpeg }
        default { return [System.Drawing.Imaging.ImageFormat]::Jpeg }
    }
}

function Add-TimestampOverlay {
    param(
        [System.Drawing.Bitmap]$Bitmap,
        [DateTime]$DateTime,
        [int]$PhotoNumber
    )
    
    $graphics = $null
    $font = $null
    $blackBrush = $null
    $yellowBrush = $null
    
    try {
        $graphics = [System.Drawing.Graphics]::FromImage($Bitmap)
        $graphics.SmoothingMode = "AntiAlias"
        $graphics.TextRenderingHint = "ClearTypeGridFit"
        
        # Scale font size based on image dimensions
        $fontSize = [Math]::Max(16, [Math]::Min(48, $Bitmap.Width / 40))
        $font = New-Object System.Drawing.Font("Consolas", [float]$fontSize, [System.Drawing.FontStyle]::Bold)
        
        # ============================================================================
        # BOTTOM-RIGHT: Date/Time stamp
        # ============================================================================
        $dateText = $DateTime.ToString("HH:mm:ss dd/MM/yyyy")
        $dateTextSize = $graphics.MeasureString($dateText, $font)
        $padding = [int]($fontSize * 0.5)
        $margin = [int]($fontSize * 0.8)
        
        $dateRectWidth = [int][Math]::Ceiling($dateTextSize.Width) + ($padding * 2)
        $dateRectHeight = [int][Math]::Ceiling($dateTextSize.Height) + ($padding * 2)
        $dateX = [Math]::Max(0, $Bitmap.Width - $dateRectWidth - $margin)
        $dateY = [Math]::Max(0, $Bitmap.Height - $dateRectHeight - $margin)
        
        # Draw semi-transparent black background for date
        $blackBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200, 0, 0, 0))
        $dateBackgroundRect = New-Object System.Drawing.Rectangle($dateX, $dateY, $dateRectWidth, $dateRectHeight)
        $graphics.FillRectangle($blackBrush, $dateBackgroundRect)
        
        # Draw yellow text for date
        $yellowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 220, 0))
        $graphics.DrawString($dateText, $font, $yellowBrush, ($dateX + $padding), ($dateY + $padding))
        
        # ============================================================================
        # TOP-LEFT: Photo number
        # ============================================================================
        $photoText = "photo $PhotoNumber"
        $photoTextSize = $graphics.MeasureString($photoText, $font)
        
        $photoRectWidth = [int][Math]::Ceiling($photoTextSize.Width) + ($padding * 2)
        $photoRectHeight = [int][Math]::Ceiling($photoTextSize.Height) + ($padding * 2)
        $photoX = $margin
        $photoY = $margin
        
        # Draw semi-transparent black background for photo number
        $photoBackgroundRect = New-Object System.Drawing.Rectangle($photoX, $photoY, $photoRectWidth, $photoRectHeight)
        $graphics.FillRectangle($blackBrush, $photoBackgroundRect)
        
        # Draw yellow text for photo number
        $graphics.DrawString($photoText, $font, $yellowBrush, ($photoX + $padding), ($photoY + $padding))
        
    } finally {
        if ($null -ne $yellowBrush) { $yellowBrush.Dispose() }
        if ($null -ne $blackBrush) { $blackBrush.Dispose() }
        if ($null -ne $font) { $font.Dispose() }
        if ($null -ne $graphics) { $graphics.Dispose() }
    }
}

# ============================================================================
# EVENT HANDLERS
# ============================================================================

$browseButton.Add_Click({
    # Use modern Windows folder picker (Vista+ style)
    $source = @"
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public class FolderPicker
{
    [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
    private static extern int SHCreateItemFromParsingName(
        [MarshalAs(UnmanagedType.LPWStr)] string pszPath,
        IntPtr pbc,
        ref Guid riid,
        out IntPtr ppv);

    public static string Show(IntPtr owner, string title, string initialFolder)
    {
        var dialog = (IFileOpenDialog)new FileOpenDialog();
        try
        {
            dialog.SetOptions(FOS.FOS_PICKFOLDERS | FOS.FOS_FORCEFILESYSTEM);
            if (!string.IsNullOrEmpty(title))
                dialog.SetTitle(title);
            
            if (!string.IsNullOrEmpty(initialFolder) && System.IO.Directory.Exists(initialFolder))
            {
                Guid shellItemGuid = new Guid("43826D1E-E718-42EE-BC55-A1E261C37BFE");
                IntPtr ppv;
                if (SHCreateItemFromParsingName(initialFolder, IntPtr.Zero, ref shellItemGuid, out ppv) == 0)
                {
                    IShellItem item = (IShellItem)Marshal.GetObjectForIUnknown(ppv);
                    dialog.SetFolder(item);
                    Marshal.Release(ppv);
                }
            }
            
            if (dialog.Show(owner) != 0)
                return null;
            
            IShellItem result;
            dialog.GetResult(out result);
            string path;
            result.GetDisplayName(SIGDN.SIGDN_FILESYSPATH, out path);
            return path;
        }
        finally
        {
            Marshal.ReleaseComObject(dialog);
        }
    }

    [ComImport, Guid("DC1C5A9C-E88A-4dde-A5A1-60F82A20AEF7")]
    private class FileOpenDialog { }

    [ComImport, Guid("d57c7288-d4ad-4768-be02-9d969532d960"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IFileOpenDialog
    {
        [PreserveSig] int Show([In] IntPtr parent);
        void SetFileTypes();
        void SetFileTypeIndex([In] uint iFileType);
        void GetFileTypeIndex(out uint piFileType);
        void Advise();
        void Unadvise();
        void SetOptions([In] FOS fos);
        void GetOptions(out FOS pfos);
        void SetDefaultFolder(IShellItem psi);
        void SetFolder(IShellItem psi);
        void GetFolder(out IShellItem ppsi);
        void GetCurrentSelection(out IShellItem ppsi);
        void SetFileName([In, MarshalAs(UnmanagedType.LPWStr)] string pszName);
        void GetFileName([MarshalAs(UnmanagedType.LPWStr)] out string pszName);
        void SetTitle([In, MarshalAs(UnmanagedType.LPWStr)] string pszTitle);
        void SetOkButtonLabel([In, MarshalAs(UnmanagedType.LPWStr)] string pszText);
        void SetFileNameLabel([In, MarshalAs(UnmanagedType.LPWStr)] string pszLabel);
        void GetResult(out IShellItem ppsi);
        void AddPlace(IShellItem psi, int alignment);
        void SetDefaultExtension([In, MarshalAs(UnmanagedType.LPWStr)] string pszDefaultExtension);
        void Close(int hr);
        void SetClientGuid();
        void ClearClientData();
        void SetFilter([MarshalAs(UnmanagedType.Interface)] IntPtr pFilter);
        void GetResults();
        void GetSelectedItems();
    }

    [ComImport, Guid("43826D1E-E718-42EE-BC55-A1E261C37BFE"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IShellItem
    {
        void BindToHandler();
        void GetParent();
        void GetDisplayName([In] SIGDN sigdnName, [MarshalAs(UnmanagedType.LPWStr)] out string ppszName);
        void GetAttributes();
        void Compare();
    }

    [Flags]
    private enum FOS : uint
    {
        FOS_PICKFOLDERS = 0x20,
        FOS_FORCEFILESYSTEM = 0x40
    }

    private enum SIGDN : uint
    {
        SIGDN_FILESYSPATH = 0x80058000
    }
}
"@
    
    if (-not ([System.Management.Automation.PSTypeName]'FolderPicker').Type) {
        Add-Type -TypeDefinition $source -ReferencedAssemblies @('System.Windows.Forms')
    }
    
    $selectedPath = [FolderPicker]::Show($form.Handle, "Select folder containing photos", [Environment]::GetFolderPath('MyPictures'))
    
    if ($selectedPath) {
        $script:Folder = $selectedPath
        $folderTextBox.Text = $script:Folder
        $folderTextBox.ForeColor = $Theme.Text
        $startButton.Enabled = $true
        $fileNameLabel.Text = "Ready to process photos"
        $dateInfoLabel.Text = ""
    }
})

$cancelButton.Add_Click({
    $script:CancelRequested = $true
    $cancelButton.Enabled = $false
    $fileNameLabel.Text = "Canceling..."
    $fileNameLabel.ForeColor = $Theme.Warning
})

$startButton.Add_Click({
    # Validate folder
    if (-not $script:Folder -or -not (Test-Path -LiteralPath $script:Folder)) {
        [System.Windows.Forms.MessageBox]::Show(
            "Please select a valid folder first.",
            "SnapStamp",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        return
    }
    
    # Create output directory
    $script:OutputDir = Join-Path $script:Folder "stamped"
    if (-not (Test-Path -LiteralPath $script:OutputDir)) {
        New-Item -ItemType Directory -Path $script:OutputDir -Force | Out-Null
    }
    
    # Get files
    $files = @(Get-ChildItem -LiteralPath $script:Folder -File | Where-Object {
        $script:Extensions -contains $_.Extension.ToLowerInvariant()
    })
    
    if ($files.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "No supported image files found in the selected folder.",
            "SnapStamp",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
        return
    }
    
    # Reset state
    $script:CancelRequested = $false
    $script:ShellDateTakenIndex = -1
    
    # Update UI
    $startButton.Enabled = $false
    $browseButton.Enabled = $false
    $cancelButton.Enabled = $true
    $progressBar.Maximum = $files.Count
    $progressBar.Value = 0
    $countLabel.Text = "0 / $($files.Count)"
    $percentLabel.Text = "0%"
    
    $processed = 0
    $failed = 0
    $noExifCount = 0
    $photoNumber = 0
    
    foreach ($file in $files) {
        if ($script:CancelRequested) { break }
        
        $image = $null
        $bitmap = $null
        $preview = $null
        
        try {
            # Update status
            $fileNameLabel.Text = $file.Name
            $fileNameLabel.ForeColor = $Theme.Text
            $dateInfoLabel.Text = "Reading metadata..."
            [System.Windows.Forms.Application]::DoEvents()
            
            # Load image
            $image = Get-ImageBitmap -File $file
            
            # Get date
            $dateResult = Get-PhotoDateTime -Image $image -File $file
            $photoDate = $dateResult.Date
            $dateSource = $dateResult.Source
            
            # Format display: HH:mm:ss dd/MM/yyyy
            $dateInfoLabel.Text = "Date: $($photoDate.ToString('HH:mm:ss dd/MM/yyyy')) ($dateSource)"
            if ($dateSource -like "*NO EXIF*") {
                $dateInfoLabel.ForeColor = $Theme.Warning
                $noExifCount++
            } else {
                $dateInfoLabel.ForeColor = $Theme.Success
            }
            
            # Create stamped bitmap
            $bitmap = New-Object System.Drawing.Bitmap($image.Width, $image.Height)
            $g = [System.Drawing.Graphics]::FromImage($bitmap)
            $g.DrawImage($image, 0, 0, $image.Width, $image.Height)
            $g.Dispose()
            
            # Increment photo number for this successfully processed image
            $photoNumber++
            Add-TimestampOverlay -Bitmap $bitmap -DateTime $photoDate -PhotoNumber $photoNumber
            
            # Save
            $outExt = if ($file.Extension.ToLowerInvariant() -in @(".heic", ".heif")) { ".jpg" } else { $file.Extension }
            $outName = [System.IO.Path]::ChangeExtension($file.Name, $outExt)
            $outPath = Join-Path $script:OutputDir $outName
            $format = Get-OutputFormat -Extension $file.Extension
            
            $bitmap.Save($outPath, $format)
            
            # Update preview
            $preview = New-Object System.Drawing.Bitmap($bitmap)
            if ($null -ne $pictureBox.Image) { $pictureBox.Image.Dispose() }
            $pictureBox.Image = $preview
            $preview = $null
            
            $processed++
            
        } catch {
            $failed++
            $dateInfoLabel.Text = "ERROR: $($_.Exception.Message)"
            $dateInfoLabel.ForeColor = [System.Drawing.Color]::OrangeRed
            Write-Warning "Failed: $($file.FullName) - $($_.Exception.Message)"
        } finally {
            if ($null -ne $bitmap) { $bitmap.Dispose() }
            if ($null -ne $image) { $image.Dispose() }
        }
        
        # Update progress
        $current = $processed + $failed
        $progressBar.Value = $current
        $percent = [Math]::Round(($current / $files.Count) * 100)
        $countLabel.Text = "$current / $($files.Count)"
        $percentLabel.Text = "$percent%"
        
        [System.Windows.Forms.Application]::DoEvents()
    }
    
    # Re-enable controls
    $startButton.Enabled = $true
    $browseButton.Enabled = $true
    $cancelButton.Enabled = $false
    
    # Show result
    if ($script:CancelRequested) {
        $fileNameLabel.Text = "Canceled by user"
        $fileNameLabel.ForeColor = $Theme.Warning
        [System.Windows.Forms.MessageBox]::Show(
            "Processing was canceled.`n`nProcessed: $processed files`nFailed: $failed files",
            "SnapStamp",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
    } else {
        $fileNameLabel.Text = "Completed!"
        $fileNameLabel.ForeColor = $Theme.Success
        $dateInfoLabel.Text = ""
        
        $warningMsg = ""
        if ($noExifCount -gt 0) {
            $warningMsg = "`n`nWARNING: $noExifCount file(s) had no EXIF data.`nThese used file creation time which may be wrong`nif the files were copied/downloaded."
        }
        
        $result = [System.Windows.Forms.MessageBox]::Show(
            "Processing complete!`n`nProcessed: $processed files`nFailed: $failed files$warningMsg`n`nOutput folder:`n$($script:OutputDir)`n`nOpen output folder?",
            "SnapStamp",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        
        if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
            Start-Process explorer.exe -ArgumentList $script:OutputDir
        }
    }
})

# ============================================================================
# SHOW FORM
# ============================================================================
[void]$form.ShowDialog()
