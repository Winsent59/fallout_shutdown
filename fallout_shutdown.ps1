# ===============================
# HIDE POWERSHELL WINDOW
# ===============================
Add-Type -Name Win32 -Namespace Console -MemberDefinition @"
[DllImport("kernel32.dll")]
public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
"@

$hwnd = [Console.Win32]::GetConsoleWindow()
if ($hwnd -ne 0) {
    [Console.Win32]::ShowWindow($hwnd, 0)  # 0 = SW_HIDE
}

# ===============================
# LOAD UI ASSEMBLIES
# ===============================
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ===============================
# FORM
# ===============================
$form = New-Object System.Windows.Forms.Form
$form.Text = "ROBCO TERMINAL"
$form.BackColor = "Black"
$form.ForeColor = "Lime"
$form.Width = 650
$form.Height = 400
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.Font = New-Object System.Drawing.Font("Consolas", 12)

# ===============================
# HEADER LABEL
# ===============================
$label = New-Object System.Windows.Forms.Label
$label.AutoSize = $true
$label.ForeColor = "Lime"
$label.BackColor = "Black"
$label.Location = New-Object System.Drawing.Point(20,20)
$label.Text = @"
==============================================================
   ROBCO INDUSTRIES UNIFIED OPERATING SYSTEM
==============================================================

   VAULT-TEC MAINFRAME ACCESS TERMINAL
   FALLOUT SYSTEM BOOT MODULE v1.3

   AUTHORIZED VAULT DWELLER INTERFACE
   © 2077 MARIK TEC. INDUSTRIES
"@
$form.Controls.Add($label)

# ===============================
# PROGRESS LABEL (FALLOUT STYLE)
# ===============================
$progressLabel = New-Object System.Windows.Forms.Label
$progressLabel.AutoSize = $true
$progressLabel.ForeColor = "Lime"
$progressLabel.BackColor = "Black"
$progressLabel.Location = New-Object System.Drawing.Point(20,210)
$progressLabel.Text = "SYSTEM BOOT: [..............................] 0%"
$form.Controls.Add($progressLabel)

# ===============================
# TIMER LABEL
# ===============================
$timerLabel = New-Object System.Windows.Forms.Label
$timerLabel.AutoSize = $true
$timerLabel.ForeColor = "Lime"
$timerLabel.BackColor = "Black"
$timerLabel.Location = New-Object System.Drawing.Point(20,240)
$timerLabel.Text = "Auto shutdown in 10 seconds"
$form.Controls.Add($timerLabel)

# ===============================
# BUTTONS
# ===============================
$yesBtn = New-Object System.Windows.Forms.Button
$yesBtn.Text = "YES - Shutdown"
$yesBtn.Width = 200
$yesBtn.Height = 40
$yesBtn.Location = New-Object System.Drawing.Point(60,290)
$yesBtn.BackColor = "Black"
$yesBtn.ForeColor = "Lime"
$yesBtn.FlatStyle = "Flat"
$form.Controls.Add($yesBtn)

$noBtn = New-Object System.Windows.Forms.Button
$noBtn.Text = "NO - Abort"
$noBtn.Width = 200
$noBtn.Height = 40
$noBtn.Location = New-Object System.Drawing.Point(320,290)
$noBtn.BackColor = "Black"
$noBtn.ForeColor = "Lime"
$noBtn.FlatStyle = "Flat"
$form.Controls.Add($noBtn)

# ===============================
# SOUNDS (SAFE)
# ===============================
try { [Console]::Beep(900,150) } catch {}
try { [Console]::Beep(700,150) } catch {}

# ===============================
# PROGRESS / TIMER LOGIC
# ===============================
$global:progress = 0          # 0–100 %
$global:ticks = 0             # 0–100 (каждый тик = 0.1 сек)
$totalTicks = 100             # 100 тиков = 10 секунд
$totalBlocks = 30             # длина полосы

function Update-Progress {
    param([int]$percent)

    if ($percent -lt 0) { $percent = 0 }
    if ($percent -gt 100) { $percent = 100 }

    $filledBlocks = [int]([double]$totalBlocks * $percent / 100)
    $emptyBlocks  = $totalBlocks - $filledBlocks

    $filled = "█" * $filledBlocks
    $empty  = "░" * $emptyBlocks

    $progressLabel.Text = "SYSTEM BOOT: [$filled$empty] $percent`%"
    $remainingSeconds = [Math]::Max(0, [int]((100 - $percent) / 10))
    $timerLabel.Text = "Auto shutdown in $remainingSeconds seconds"
}

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 100   # 0.1 сек

$timer.Add_Tick({
    $global:ticks++
    $global:progress = $global:ticks  # 1 тик = 1%

    if ($global:progress -gt 100) {
        $global:progress = 100
    }

    Update-Progress -percent $global:progress

    if ($global:progress -ge 100) {
        $timer.Stop()
        try { [Console]::Beep(1000,500) } catch {}
        Stop-Computer -Force
        [System.Environment]::Exit(0)
    }
})

Update-Progress -percent 0
$timer.Start()

# ===============================
# BUTTON EVENTS
# ===============================
$yesBtn.Add_Click({
    $timer.Stop()
    try { [Console]::Beep(1000,500) } catch {}
    Stop-Computer -Force
    [System.Environment]::Exit(0)
})

$noBtn.Add_Click({
    $timer.Stop()
    try { [Console]::Beep(500,300) } catch {}
    [System.Environment]::Exit(0)
})

# ===============================
# RUN UI
# ===============================
$form.ShowDialog()
[System.Environment]::Exit(0)
