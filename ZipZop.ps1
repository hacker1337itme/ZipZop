# Load necessary assemblies for PDF creation
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName PdfSharp

# Function to create a new PDF file with embedded text content
function Create-PDFWithEmbeddedContent {
    param (
        [string]$pdfPath,
        [array]$content
    )

    $doc = New-Object PdfSharp.Pdf.PdfDocument
    $doc.Info.Title = "Embedded ZIP Content"

    foreach ($text in $content) {
        $page = $doc.AddPage()
        $gfx = [PdfSharp.Drawing.XGraphics]::FromPdfPage($page)

        $font = New-Object PdfSharp.Drawing.XFont("Verdana", 20, [PdfSharp.Drawing.XFontStyle]::Regular)
        $gfx.DrawString($text, $font, [PdfSharp.Drawing.XBrushes]::Black, 50, 100)
    }

    $doc.Save($pdfPath)
    $doc.Close()
}

# Function to download a ZIP file from a URL
function Download-ZipFile {
    param (
        [string]$url,
        [string]$outputPath
    )

    $client = New-Object System.Net.WebClient
    $client.DownloadFile($url, $outputPath)
}

# Main function to handle the entire process
function ZipZop {
    param (
        [string]$zipUrl,
        [string]$outputPdfPath
    )

    # Download the ZIP file
    $zipPath = [System.IO.Path]::GetTempFileName() + ".zip"
    Download-ZipFile -url $zipUrl -outputPath $zipPath
    Write-Host "Downloaded ZIP file to: $zipPath"

    # Temporary directory to extract ZIP contents
    $tempDir = [System.IO.Path]::GetTempPath() + [System.IO.Path]::GetRandomFileName()
    New-Item -ItemType Directory -Path $tempDir | Out-Null

    # Extract the ZIP file
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $tempDir)

    # Read content from extracted files
    $fileContents = @()
    $files = Get-ChildItem -Path $tempDir -Recurse
    foreach ($file in $files) {
        if ($file.Extension -match '\.txt$') {
            # Read text files only for simplicity
            $fileContents += Get-Content $file.FullName -Raw
        }
    }

    # Create PDF with extracted content
    Create-PDFWithEmbeddedContent -pdfPath $outputPdfPath -content $fileContents

    # Clean up the temporary files
    Remove-Item -Path $zipPath -Force
    Remove-Item -Path $tempDir -Recurse -Force

    Write-Host "Created PDF at: $outputPdfPath"
}

# Command-line arguments
param (
    [string]$ZipFileUrl = $(throw "Please provide a URL for the ZIP file using -ZipFileUrl"),
    [string]$PdfOutputPath = $(throw "Please provide an output path for the PDF using -PdfOutputPath")
)

# Call the main function with provided arguments
ZipZop -zipUrl $ZipFileUrl -outputPdfPath $PdfOutputPath
