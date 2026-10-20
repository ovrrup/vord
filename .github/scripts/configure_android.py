import os

# Configure Kotlin DSL build.gradle.kts
kts_path = 'android/app/build.gradle.kts'
if os.path.exists(kts_path):
    with open(kts_path, 'r', encoding='utf-8') as f:
        kts = f.read()
    if 'compileOptions {' in kts:
        if 'isCoreLibraryDesugaringEnabled' not in kts:
            kts = kts.replace('compileOptions {', 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true')
    else:
        kts += '\nandroid {\n    compileOptions {\n        isCoreLibraryDesugaringEnabled = true\n    }\n}\n'
    if 'defaultConfig {' in kts and 'multiDexEnabled' not in kts:
        kts = kts.replace('defaultConfig {', 'defaultConfig {\n        multiDexEnabled = true')
    if 'coreLibraryDesugaring' not in kts:
        kts += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
    with open(kts_path, 'w', encoding='utf-8') as f:
        f.write(kts)

# Configure Groovy build.gradle
groovy_path = 'android/app/build.gradle'
if os.path.exists(groovy_path):
    with open(groovy_path, 'r', encoding='utf-8') as f:
        groovy = f.read()
    if 'compileOptions {' in groovy:
        if 'coreLibraryDesugaringEnabled' not in groovy:
            groovy = groovy.replace('compileOptions {', 'compileOptions {\n        coreLibraryDesugaringEnabled true')
    else:
        groovy += '\nandroid {\n    compileOptions {\n        coreLibraryDesugaringEnabled true\n    }\n}\n'
    if 'defaultConfig {' in groovy and 'multiDexEnabled' not in groovy:
        groovy = groovy.replace('defaultConfig {', 'defaultConfig {\n        multiDexEnabled true')
    if 'coreLibraryDesugaring' not in groovy:
        groovy += "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n}\n"
    with open(groovy_path, 'w', encoding='utf-8') as f:
        f.write(groovy)
