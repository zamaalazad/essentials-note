# ===================================================================
#   Laravel Project Setup Script for Windows PowerShell
#
#   এই স্ক্রিপ্টটি একটি নতুন লারাভেল প্রজেক্ট স্বয়ংক্রিয়ভাবে তৈরি ও
#   কনফিগার করার জন্য ডিজাইন করা হয়েছে।
#
#   ব্যবহারবিধি:
#   1. এই ফাইলটি `Setup-Laravel.ps1` নামে সেভ করুন।
#   2. PowerShell টার্মিনাল খুলুন।
#   3. প্রথমবার ব্যবহারের জন্য `Set-ExecutionPolicy RemoteSigned -Scope Process`
#      কমান্ডটি চালিয়ে এক্সিকিউশন পলিসি ঠিক করুন।
#   4. যে ফোল্ডারে নতুন প্রজেক্ট তৈরি করতে চান, সেখানে যান।
#   5. `./Setup-Laravel.ps1` কমান্ডটি চালিয়ে স্ক্রিপ্টটি রান করুন।
# ===================================================================

# --- ধাপ ১: ব্যবহারকারীর কাছ থেকে তথ্য সংগ্রহ ---
Write-Host "Laravel Project Setup Automation" -ForegroundColor Yellow
$projectName = Read-Host "প্রজেক্টের নাম দিন (e.g., my-awesome-app)"
$dbName = Read-Host "ডাটাবেজের নাম দিন (খালি রাখলে প্রজেক্টের নাম ব্যবহৃত হবে)"

# যদি ডাটাবেজের নাম খালি থাকে, তাহলে প্রজেক্টের নাম ব্যবহার করুন
if (-not $dbName) {
    # প্রজেক্টের নামের '-' কে '_' দিয়ে রিপ্লেস করা হচ্ছে ডাটাবেজের জন্য
    $dbName = $projectName.Replace('-', '_')
    Write-Host "ডাটাবেজের নাম হিসেবে '$dbName' ব্যবহৃত হচ্ছে।" -ForegroundColor Cyan
}

# MySQL root পাসওয়ার্ডের জন্য প্রোমপ্ট
Write-Host "ডাটাবেজ তৈরি করার জন্য আপনার MySQL root পাসওয়ার্ড প্রয়োজন হবে।" -ForegroundColor Yellow
$dbRootPassword = Read-Host -AsSecureString "আপনার MySQL root পাসওয়ার্ড দিন"

# --- ধাপ ২: প্রয়োজনীয় টুলস পরীক্ষা করা ---
Write-Host ""
Write-Host "প্রয়োজনীয় টুলস (PHP, Composer, NPM, MySQL) পরীক্ষা করা হচ্ছে..." -ForegroundColor Green

function Check-Command {
    param ($command)
    try {
        Get-Command $command -ErrorAction Stop | Out-Null
        Write-Host "✅  $command পাওয়া গেছে।" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌  $command পাওয়া যায়নি। অনুগ্রহ করে এটি ইনস্টল করুন এবং PATH-এ যোগ করুন।" -ForegroundColor Red
        return $false
    }
}

$phpExists = Check-Command "php"
$composerExists = Check-Command "composer"
$npmExists = Check-Command "npm"
$mysqlExists = Check-Command "mysql"

if (-not ($phpExists -and $composerExists -and $npmExists -and $mysqlExists)) {
    Write-Host "`nপ্রয়োজনীয় সকল টুলস ইনস্টল করা নেই। প্রোগ্রাম বন্ধ করা হচ্ছে।" -ForegroundColor Red
    # Exit the script
    return
}


# --- ধাপ ৩: লারাভেল প্রজেক্ট তৈরি করা ---
Write-Host "`nComposer দিয়ে '$projectName' প্রজেক্টটি তৈরি করা হচ্ছে... (এতে কিছু সময় লাগতে পারে)" -ForegroundColor Cyan
try {
    composer create-project laravel/laravel "$projectName" --quiet
    Write-Host "✅  লারাভেল প্রজেক্ট সফলভাবে তৈরি হয়েছে।" -ForegroundColor Green
} catch {
    Write-Host "❌  লারাভেল প্রজেক্ট তৈরিতে সমস্যা হয়েছে। Composer এর আউটপুট দেখুন।" -ForegroundColor Red
    return
}


# --- ধাপ ৪: প্রজেক্ট ডিরেক্টরিতে প্রবেশ এবং .env ফাইল কনফিগারেশন ---
Set-Location -Path $projectName
Write-Host "`n'$projectName' ফোল্ডারে প্রবেশ করা হয়েছে।" -ForegroundColor Cyan

# .env.example থেকে .env ফাইল তৈরি
if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "✅  .env ফাইল তৈরি হয়েছে।" -ForegroundColor Green
}

# .env ফাইলে ডাটাবেজের তথ্য আপডেট করা
Write-Host "ডাটাবেজ কানেকশনের জন্য .env ফাইল আপডেট করা হচ্ছে..."
$envContent = Get-Content .env
$envContent = $envContent -replace 'DB_DATABASE=laravel', "DB_DATABASE=$dbName"
$envContent = $envContent -replace 'DB_USERNAME=root', "DB_USERNAME=root"
$envContent = $envContent -replace 'DB_PASSWORD=', "DB_PASSWORD=`"$([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($dbRootPassword)))`""
$envContent | Set-Content .env
Write-Host "✅  .env ফাইল আপডেট করা হয়েছে।" -ForegroundColor Green


# --- ধাপ ৫: ডাটাবেজ তৈরি এবং মাইগ্রেশন ---
Write-Host "MySQL সার্ভারে '$dbName' ডাটাবেজটি তৈরি করা হচ্ছে..."
$mysqlPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($dbRootPassword))
try {
    # SQL কোডটি একটি ভ্যারিয়েবলে রাখা হলো
    $sqlQuery = "CREATE DATABASE \`$dbName\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    # mysql কমান্ড চালানো
    echo $sqlQuery | mysql -u root -p"$mysqlPassword"
    Write-Host "✅  '$dbName' ডাটাবেজ সফলভাবে তৈরি হয়েছে।" -ForegroundColor Green
} catch {
    Write-Host "❌  ডাটাবেজ তৈরিতে সমস্যা হয়েছে। ডাটাবেজটি আগে থেকেই থাকতে পারে অথবা পাসওয়ার্ড ভুল।" -ForegroundColor Red
    # You can decide to continue or exit here. For now, we continue to migration.
}

Write-Host "Application Key জেনারেট করা হচ্ছে..."
php artisan key:generate

Write-Host "ডাটাবেজ মাইগ্রেশন চালানো হচ্ছে..."
try {
    php artisan migrate
    Write-Host "✅  মাইগ্রেশন সফলভাবে সম্পন্ন হয়েছে।" -ForegroundColor Green
} catch {
    Write-Host "❌  মাইগ্রেশন ব্যর্থ হয়েছে। .env ফাইলের ডাটাবেজ তথ্য এবং MySQL সার্ভার পরীক্ষা করুন।" -ForegroundColor Red
}


# --- ধাপ ৬: ফ্রন্টএন্ড (VueJS) সেটআপ ---
Write-Host "`nNPM প্যাকেজ ইনস্টল করা হচ্ছে... (এতে অনেক সময় লাগতে পারে)" -ForegroundColor Cyan
try {
    npm install
    Write-Host "✅  NPM প্যাকেজ সফলভাবে ইনস্টল হয়েছে।" -ForegroundColor Green
} catch {
    Write-Host "❌  NPM প্যাকেজ ইনস্টলেশনে সমস্যা হয়েছে।" -ForegroundColor Red
}


# --- ধাপ ৭: চূড়ান্ত ধাপ ---
# Git repository শুরু করা
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host "`nGit repository শুরু করা হচ্ছে..." -ForegroundColor Cyan
    git init
    git add .
    git commit -m "Initial commit - project setup by PowerShell script"
    Write-Host "✅  প্রাথমিক Git কমিট সম্পন্ন হয়েছে।" -ForegroundColor Green
}

# VS Code-এ প্রজেক্ট খোলা
if (Get-Command code -ErrorAction SilentlyContinue) {
    Write-Host "Visual Studio Code-এ প্রজেক্টটি খোলা হচ্ছে..." -ForegroundColor Cyan
    code .
}

Write-Host "`n🎉 সেটআপ সম্পন্ন! 🎉`" -ForegroundColor Yellow
Write-Host "এখন আপনি দুটি টার্মিনাল খুলে নিম্নলিখিত কমান্ডগুলো চালাতে পারেন:"
Write-Host "   1. `php artisan serve` (API সার্ভার চালু করার জন্য)"
Write-Host "   2. `npm run dev` (Vite ফ্রন্টএন্ড সার্ভার চালু করার জন্য)"