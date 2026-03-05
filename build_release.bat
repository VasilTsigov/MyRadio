@echo off
set "JAVA_HOME=C:\Program Files\Android\Android Studio\jbr"
cd /d C:\Users\vasil\MyRadio
echo JAVA_HOME is: %JAVA_HOME%
echo Running gradlew...
call gradlew.bat assembleRelease --no-daemon > C:\Users\vasil\MyRadio\build_log.txt 2>&1
echo Exit code: %ERRORLEVEL%
echo Done.
