"""يُشغَّل بعد flutter create: يضبط اسم التطبيق والتوقيع الثابت (ضروري للتحديث دون فقدان البيانات)."""
import re, pathlib

man = pathlib.Path('android/app/src/main/AndroidManifest.xml')
t = man.read_text(encoding='utf-8')
t = re.sub(r'android:label="[^"]*"', 'android:label="Alum Glass"', t, count=1)
man.write_text(t, encoding='utf-8')

g = pathlib.Path('android/app/build.gradle.kts')
s = g.read_text(encoding='utf-8')
if 'keystoreProperties' not in s:
    header = '''import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

'''
    signing = '''signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {'''
    s = header + s
    s = s.replace('buildTypes {', signing, 1)
    s = s.replace('signingConfig = signingConfigs.getByName("debug")',
                  'signingConfig = if (keystorePropertiesFile.exists()) signingConfigs.getByName("release") else signingConfigs.getByName("debug")')
    g.write_text(s, encoding='utf-8')
print('patched')
