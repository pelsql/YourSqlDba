param(
  [string]$File,      # "$(ItemPath)"
  [string]$FileName   # "$(ItemFileName)"
)

Try {

# Fichier par défaut si aucun argument (lancement manuel possible)
# --- Vérif fichier ---
    if ([string]::IsNullOrWhiteSpace($File) -or -not (Test-Path $File)) {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show(
            "Fichier introuvable ou invalide :`n$File",
            "Goto-Mark",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
        return
    }

    # --- Chercher les @@MARK ---
    $matches = Select-String -Path $File -Pattern '^\s*--\s*@@MARK:' -ErrorAction SilentlyContinue

    if (-not $matches -or $matches.Count -eq 0) {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show(
            "Aucun @@MARK trouvé dans :`n$File",
            "Goto-Mark",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
        return
    }

# --- Construire la liste pour Out-GridView ---
    $items = foreach ($m in $matches) {
        [pscustomobject]@{
            Line = $m.LineNumber
            Mark = $m.Line.Trim()
        }
    }

    # --- Sélection via Out-GridView ---
    $title = "Sélectionnez un @@MARK"
    if (-not [string]::IsNullOrWhiteSpace($FileName)) {
        $title += " ($FileName)"
    }

    $selection = $items | Out-GridView -Title $title -PassThru

    # Si l'utilisateur annule / ferme la fenêtre
    if (-not $selection) {
        return
    }

    $line = [int]$selection.Line

    # --- Trouver le bon process SSMS ---
    $allSsms = Get-Process -Name "ssms" -ErrorAction SilentlyContinue
    if (-not $allSsms) {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show(
            "Processus SSMS (ssms.exe) introuvable.",
            "Goto-Mark",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
        return
    }

    $ssms = $null

    if (-not [string]::IsNullOrWhiteSpace($FileName)) {
        $ssms = $allSsms |
            Where-Object { $_.MainWindowTitle -like "*$FileName*" } |
            Select-Object -First 1
    }

    if (-not $ssms) {
        # Fallback : premier SSMS trouvé
        $ssms = $allSsms | Select-Object -First 1
    }

    if (-not $ssms) {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show(
            "Impossible de cibler une fenêtre SSMS.",
            "Goto-Mark",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
        return
    }

    # --- Activer SSMS + envoyer Ctrl+G / ligne ---
    Add-Type -AssemblyName Microsoft.VisualBasic
    Add-Type -AssemblyName System.Windows.Forms

    # Activer SSMS
    [Microsoft.VisualBasic.Interaction]::AppActivate($ssms.Id) | Out-Null
    Start-Sleep -Milliseconds 200  # essentiel

    # Envoyer Ctrl+G
    [System.Windows.Forms.SendKeys]::SendWait("^{g}")
    Start-Sleep -Milliseconds 200  # ESSENTIEL : laisser SSMS initialiser la boîte

    # Envoyer la ligne (séparé)
    [System.Windows.Forms.SendKeys]::SendWait("$line")
    Start-Sleep -Milliseconds 100

    # Valider par ENTER (jamais par OK)
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")

}
catch {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show(
        "Erreur : $($_.Exception.Message)",
        "Goto-Mark.ps1",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    )
}