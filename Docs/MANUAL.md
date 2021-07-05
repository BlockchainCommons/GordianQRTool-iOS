# Goardian QR Tool Manual

<a href="https://raw.githubusercontent.com/BlockchainCommons/GordianQRTool-iOS/shannona-qr-docs/images/qr-list.jpeg"><img src="https://raw.githubusercontent.com/BlockchainCommons/GordianQRTool-iOS/shannona-qr-docs/images/qr-list.jpeg" align="right" width=250></a>

**Gordian QR Tool** is an app that allows you to securely store QR codes containing confidential information such as cryptoseeds, private keys, 2FA seeds, vaccination records, and COVID test results. It improves on the usability and security of traditional methods for storing QRs (such as printing them out or saving them to a camera roll).

Why use **QR Tool**? So that you always know where your vital QRs are (particularly 2FA seeds and crypto seeds), so that you can store QRs for friends and family (particularly SSKR shares), so that you know they're safe, and so that you can easily access them.

**Usability Features:**

* Import via QR or clipboard
* Export QR or text via Apple's Share Extensions
* Sort via category, name, or date

**Security Features:**

* Stored in your iPhone Secure Enclave
* Protected via 2FA: you must login in to your Apple account, then you must verify with biometrics whenever you access the app
* Automated iCloud backup and recovery

**QR Tool** is a reference app, demonstrating the [Gordian Principles](https://github.com/BlockchainCommons/GordianQRTool-iOS#gordian-principles) of independence, privacy, resilience, and openness.

## Install QR Tool

You can either purchase **Gordian QR Tool** from the Apple store or you can compile from the source here.

For full functionality of the iCloud backup, be sure to turn on the following functionality under "Settings > Apple ID > iCloud" on all devices running **Gordian QR Tool**:

* Keychain
* iCloud Drive

## Using QR Tool

In **QR Tool** you can import QRs, edit QR metadata, view QRs, and export QRs.

### Using the Main Menu

<blockquote>
  <img src="https://raw.githubusercontent.com/BlockchainCommons/GordianQRTool-iOS/shannona-qr-docs/images/qr-commands.jpg" align="center" width=500>
</blockquote>

The main screen of **QR Tool** contains all of its general functionality in a bar of icons along the top. The icons are:

* **Edit** ("Edit"). Remove QRs from your vault by clicking the red minus sign to the left. _Warning:_ if you remove a QR, it will be gone forever.
* **Refresh** (Circle Arrow). Reauthenticate if you failed to supply your biometric information when you started **QR Tool**. (You will see a blank page rather than your QR listing if you do not authenticate.)
* **QR Tool** (App Icon) See information about QR Tool and Blockchain Commons.
* **Sort** (Vertical Arrows). Choose to sort by category, name, or date added.
* **Copy** (Clipboard). Import text from your clipboard as a QR code. Ideally, this information will be typed data, such as a UR. You will see the data you're importing, and be given an opportunity to give it a label (name).
* **QR** (QR Icon). Import a QR by photographing it. You will need to provide camera permission the first time you use this. Note that you can also import from your camera roll by tapping the landscape icon at the bottom right of the camera screen. After you have imported your QR, you will have an opportunity to see the data that you're importing as well as label (name) it.

<div align="center">
  <table border=0>
    <tr>
      <td>
        <a href="https://raw.githubusercontent.com/BlockchainCommons/GordianQRTool-iOS/shannona-qr-docs/images/qr-auth.jpeg"><img src="https://raw.githubusercontent.com/BlockchainCommons/GordianQRTool-iOS/shannona-qr-docs/images/qr-auth.jpeg" width=250></a> 
        <br><div align="center"><b>Auth</b></div>
      </center></td>
      <td>
        <a href="https://raw.githubusercontent.com/BlockchainCommons/GordianQRTool-iOS/shannona-qr-docs/images/qr-sort.jpeg"><img src="https://raw.githubusercontent.com/BlockchainCommons/GordianQRTool-iOS/shannona-qr-docs/images/qr-sort.jpeg" width=250></a>
        <br><div align="center"><b>Sort</b></div>
      </center></td>
      <td>     
        <a href="https://raw.githubusercontent.com/BlockchainCommons/GordianQRTool-iOS/shannona-qr-docs/images/qr-add.jpeg"><img src="https://raw.githubusercontent.com/BlockchainCommons/GordianQRTool-iOS/shannona-qr-docs/images/qr-add.jpeg" width=250></a>
        <br><div align="center"><b>Import</b></div>
      </center></td>
    </tr>
  </table>
</div>

#### Viewing Lifehashes

A colorful square image is displayed for each QR. This is a [Lifehash](https://github.com/BlockchainCommons/bc-lifehash), which is a pictoral representation of the data stored in a QR. It's meant to help assure you that the same data is present if you store it on different devices, and also to verify that your data hasn't changed. It's particularly useful when you are moving data to a new app, as it's almost impossible to eyeball the QR itself and see that it hasn't changed. The Lifehash for the same data should always be the same; if it suddenly changes, there may be a problem that you should investigate.

<div align="center">
  <img src="https://raw.githubusercontent.com/BlockchainCommons/bc-lifehash/master/Art/version2.jpg">
</div>  
  
### Viewing & Changing QR Data

You can view any stored QR data by clicking the right arrow in your listing of QRs. The will bring you to a QR view that display all of the details of the QR, including its Lifehash, its name, its category, its QR code, and its textual description. You can change the metadata for the QR on this page, you can export it, or you can delete it.

* **Delete.** Click the trash can at the top right to remove a QR from your vault. This has the same effect as removing a QR using the "Edit" button on the main page. _Warning:_ if you remove a QR, it will be gone forever.
* **Label.** Edit the text field immediately next to the Lifehash to change the name for that QR. This metadata is only for your use, to help you recognize the QR. Be sure to click "Save" after editing the label.
* **Type.** Edit the text field immediately next to the "Type:" to change the category of a QR. If **QR Tool** recognizes a QR's type (such as a 2FA seed or an SSKR shard), it will set this automatically, but otherwise you'll want to set this by hand. Setting and maintaining consistent categories for your QRs will help you to sort them. Be sure to click "Save" after editing the category.

<div align="center">
  <table border=0>
    <tr>
      <td>
        <a href="https://raw.githubusercontent.com/BlockchainCommons/GordianQRTool-iOS/shannona-qr-docs/images/qr-seed.jpeg"><img src="https://raw.githubusercontent.com/BlockchainCommons/GordianQRTool-iOS/shannona-qr-docs/images/qr-seed.jpeg" width=250></a> 
        <br><div align="center"><b>Crypto Seed</b></div>
      </center></td>
      <td>
        <a href="https://raw.githubusercontent.com/BlockchainCommons/GordianQRTool-iOS/shannona-qr-docs/images/qr-covid.jpeg"><img src="https://raw.githubusercontent.com/BlockchainCommons/GordianQRTool-iOS/shannona-qr-docs/images/qr-covid.jpeg" width=250></a>
        <br><div align="center"><b>Vaccine Record</b></div>
      </center></td>
      <td>     
        <a href="https://raw.githubusercontent.com/BlockchainCommons/GordianQRTool-iOS/shannona-qr-docs/images/qr-edit.jpeg"><img src="https://raw.githubusercontent.com/BlockchainCommons/GordianQRTool-iOS/shannona-qr-docs/images/qr-edit.jpeg" width=250></a>
        <br><div align="center"><b>Edit Type ...</b></div>
      </center></td>
    </tr>
  </table>
</div>

### Exporting QR Data

<a href="https://raw.githubusercontent.com/BlockchainCommons/GordianQRTool-iOS/shannona-qr-docs/images/qr-export.jpeg"><img src="https://raw.githubusercontent.com/BlockchainCommons/GordianQRTool-iOS/shannona-qr-docs/images/qr-export.jpeg" align="right" width=250></a>

You can export QR data from the QR view page. There will be either two or three options.

* **QR Export.** Select the export arrow next to the QR to use the Sharing Extensions to export the QR via Airdrop, Messages, Mail, or any number of applications on your phone. Ideally, you will be able to export a QR directly to another program, but otherwise sending it via a messaging system will usually help you to move it.
* **Text Export.** Alternatively, you can just export the text encoded in the QR via the Sharing Extensions: select the export arrow next to the text.
* **UR Conversion.** Many QRs are stored as [Uniform Resources](https://github.com/BlockchainCommons/Research/blob/master/papers/bcr-2020-005-ur.md), a Blockchain Commons specification for encoding typed data, particularly meant for eficient use in QRs. For data not stored as URs, click "convert to UR". (A limited number of crypto-related data types are available for conversion.)

If you want to export a QR code to another app on your phone, and there is not an option in the Sharing Extensions, another methodology is to take a screenshot of the QR view, which will save it to front of your photo roll. You can then go to the QR import function on the other app, load it in via camera, and you should see that same landscape icon, which will allow you to import it from your camera roll. It'll be easy to find because it was just saved. Afterward, you should _remove the screenshot from your camera roll_, so that you are not storing your QR code insecurely.

## For More Info

If you have questions, comments, feature requests, or bug reports, please visit our [Gordian Discussion area](https://github.com/BlockchainCommons/Gordian/discussions) and write us a message!

