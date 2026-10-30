# Alum Glass

تطبيق Flutter عربي (RTL) لحساب وتخصيم قطاعات الألمنيوم والزجاج. لا توجد أي خصميات مضمنة؛ كل شيء يُدخل من "إعدادات القطاعات".

## مفهوم القواعد
كل **قطاع** (نظام ألمنيوم) له قواعد لكل نوع: شباك 1/2/3/4 درف، الباب، الطرف.
كل قاعدة: `الطول = (العرض أو الارتفاع − الخصمية) ÷ القسمة + الإضافة`
- مثال: عرض الدرفة في شباك درفتين: من العرض، خصمية X، قسمة 2، إضافة Y.
- قواعد الزجاج لها معادلتان (عرض وارتفاع).

## بناء APK
### الطريقة 1 (بدون تثبيت أي شيء): GitHub Actions
1. أنشئ مستودعاً على GitHub وارفع محتويات هذا المجلد.
2. تبويب Actions ← Build APK ← Run workflow.
3. حمّل `alum-glass-apk` من نتيجة التشغيل.

### الطريقة 2: على جهازك
```
flutter create --platforms=android --org com.alumglass --project-name alum_glass .
python3 tool/patch_android.py
flutter pub get
flutter build apk --release
```
الملف: `build/app/outputs/flutter-apk/app-release.apk`

## التحديث دون فقدان البيانات (مهم)
أندرويد يحدّث التطبيق فوق النسخة القديمة (وتبقى بياناته) فقط إذا كان **الـ APK موقعاً بنفس المفتاح** ونفس اسم الحزمة `com.alumglass.alum_glass`.
أنشئ مفتاحاً مرة واحدة واحفظه في مكان آمن (إن ضاع لن تستطيع التحديث فوق النسخة المثبتة):
```
keytool -genkey -v -keystore release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias alumglass
base64 -w0 release.jks     # الناتج يوضع في سر KEYSTORE_BASE64
```
في GitHub: Settings ← Secrets ← Actions، أضف: `KEYSTORE_BASE64` و`KEYSTORE_PASSWORD` و`KEY_ALIAS` (= alumglass).
للبناء المحلي ضع `android/key.properties` (storePassword, keyPassword, keyAlias, storeFile).

كذلك: زر "النسخ الاحتياطي" في إعدادات القطاعات ينسخ كل بياناتك كنص لتحفظه أو تستورده في أي وقت.
