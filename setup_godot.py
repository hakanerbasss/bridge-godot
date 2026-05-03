import os, subprocess
java = subprocess.check_output(['readlink','-f',subprocess.check_output(['which','java']).strip()]).strip().decode()
java_home = os.path.dirname(os.path.dirname(java))
home = os.environ.get('HOME', '/github/home')
sdk = '/usr/lib/android-sdk'
os.makedirs(home + '/.config/godot', exist_ok=True)
content = '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
content += 'export/android/java_sdk_path = "' + java_home + '"\n'
content += 'export/android/android_sdk_path = "' + sdk + '"\n'
content += 'export/android/debug_keystore = "/root/debug.keystore"\n'
content += 'export/android/debug_keystore_user = "androiddebugkey"\n'
content += 'export/android/debug_keystore_pass = "android"\n'
open(home + '/.config/godot/editor_settings-4.2.tres', 'w').write(content)
print('OK java=' + java_home)
