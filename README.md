# Multy-IOS

Multi cryptocurrency and assets open-source wallet

To conrtibute please check **Build instruction**

[Multy](http://multy.io)

## Build instruction

1. Clone master branch of the Multy-iOS project
```
$git clone https://github.com/Appscrunch/Multy-IOS.git
```

2. Install pods using ``` Terminal ```  <br />
```
sudo gem install cocoapods
```
   Than update it from project repository <br />
   
   
   ps. navigate to project Repository in ```Finder```<br />
   print ```cd``` in the ```Terminal``` and than drag&drop project repository to the ``` Terminal ```
   
```
pod update
```
3. From version 1.4.2 there must be added file "AppSecretInfo.swift" in folder Multy
```
import Foundation

//exchange
let apiChangellyKey = "..."
let secretChangellyKey = "..."

let apiQuickexKey = "..."
let privateQuickexKey = "..."

```
4. Please change  ```Bundle Identifier``` and ```Team``` in ```Multy Project Settings```<br />
   If you want to join our team please contact to ``` @vadimicus ```  in Telegram

5. Try to build the project on device(simulator not suported)

6. If you have problem with "ButtonProgressBar" on building process<br />
    You can use auto-fix<br />
    Or add ``` @objc ``` in begin of bug line



