#!/bin/bash
mkdir Browser1
cp -r Browser4_KLP/* Browser1
cd Browser1
find . -name "AndroidManifest.xml" -exec perl -pi -e 's/com.android.browser;browser/com.android.browser;browser1/g' {} \;
find . -name "AndroidManifest.xml" -exec perl -pi -e 's/com.android.browser.permission.READ_HISTORY_BOOKMARKS/com.android.browse.permission.READ_HISTORY_BOOKMARKS/g' {} \;
find . -name "AndroidManifest.xml" -exec perl -pi -e 's/com.android.browser.permission.WRITE_HISTORY_BOOKMARKS/com.android.browse.permission.WRITE_HISTORY_BOOKMARKS/g' {} \;
find . -name "AndroidManifest.xml" -exec perl -pi -e 's/com.android.browser/com.android.browser1/g' {} \;
find . -name "*.java" -exec perl -pi -e 's/com.android.browser/com.android.browser1/g' {} \;
find . -name "AndroidManifest.xml" -exec perl -pi -e 's/com.android.browse.permission.READ_HISTORY_BOOKMARKS/com.android.browser.permission.READ_HISTORY_BOOKMARKS/g' {} \;
find . -name "AndroidManifest.xml" -exec perl -pi -e 's/com.android.browse.permission.WRITE_HISTORY_BOOKMARKS/com.android.browser.permission.WRITE_HISTORY_BOOKMARKS/g' {} \;
find . -name "AndroidManifest.xml" -exec perl -pi -e 's/\@string\/application_name_internet/Internet1/g' {} \;
find . -name "AndroidManifest.xml" -exec perl -pi -e 's/authorities=\"com.lge.browser.backup.BackupSizeUpdateProvider/authorities=\"com.lge.browser.backup.BackupSizeUpdateProvider1/g' {} \;
mv src/com/android/browser src/com/android/browser1
