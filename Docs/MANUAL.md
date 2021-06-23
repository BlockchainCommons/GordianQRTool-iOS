# QR Tool Manual

<a href="https://raw.githubusercontent.com/BlockchainCommons/GordianQRTool-iOS/shannona-qr-docs/images/qr-list.jpeg"><img src="https://raw.githubusercontent.com/BlockchainCommons/GordianQRTool-iOS/shannona-qr-docs/images/qr-list.jpeg" align="right" width=250></a>

**QR Tool** is an app that allows you to securely store QR codes of critical information such as cryptoseeds, private keys, 2FA seeds, vaccination records, and test results. It improves the accessibility and security of traditional methods for storing QRs (such as printing them out or saving them to a camera roll).

Why use **QR Tool**? So that you always know where your vital QRs are (particularly 2FA seeds and crypto seeds0, so that you can store QRs for friends and family (particularly SSKR shares), so that you know they're safe, and so that you can easily access them.

**Accessibility Features:**

* Importing via QR or text
* Exporting via messaging services or text copy
* Sorting via category, name or date

**Security Features:**

* Stored in your phone's secure vault
* Protected via 2FA: you must login in to your Apple account, then you must verify with biometrics whenever you access the app
* Automated iCloud backup and recovery

**QR Tool** is a reference app, demonstrating the [Gordian Principles](https://github.com/BlockchainCommons/GordianQRTool-iOS#gordian-principles) of independence, privacy, resilience, and openness.

## Using QR Tool

### Using the Main Menu

In **QR Tool** you can import QRs, edit QR metadata, view QRs, and export QRs.

<blockquote>
  <img src="https://raw.githubusercontent.com/BlockchainCommons/GordianQRTool-iOS/shannona-qr-docs/images/qr-commands.jpg" align="center" width=500>
</blockquote>

The main screen of **QR Tool** contains all of its functionality in a bar of icons along the top. The icons are:

* **Edit.** ("Edit") Remove QRs from your vault by clicking the red minus sign to the left. _Warning:_ if you remove a QR, it will be gone forever.
* **Refresh.** (Circle Arrow) If you failed to supply your biometric information when you started **QR Tool**, it will come up with a blank page. Click the Refresh point to reauthenticate.
* **QR Tool.** (App Icon) Tap the central icon to see information about QR Tool and Blockchain Commons.
* **Sort.** (Vertical Arrows) Choose to sort by category, name, or date added.
* **Copy.** (Clipboard) Import text in your cut-and-paste buffer as a QR code. Ideally, this information will be typed data, such as a UR. You will see the data you're importing, and be given an opportunity to give it a label (name).
* **QR.** (QR Icon) Import a QR by photographing it. You will need to provide camera permission the first time you use it. Note that you can also import from your camera roll by tapping at the landscape icon at the bottom right. After you have imported your QR, you will have an opportunity to see the data that you're importing as well as label (name) it.

#### Viewing Lifehashes

Color square images are displayed for each QR. This is a [Lifehash](https://github.com/BlockchainCommons/bc-lifehash), which is a pictoral representation of the data stored in a QR. It's meant to help assure you that the same data is present if you store it on different devices, and also to verify that your data hasn't changed. The Lifehash for the same data should always be the same; if it suddenly changes, there may be a problem that you should investigate.

### Viewing QR Data

You can view any stored QR data by clicking the right arrow in your listing of QRs. The QR view will display all of the details of the QR, including its Lifehash, its name, its category, its qr code, and its textual description. You can change the metadata regarding a QR on this page, you can export it, or you can delete it.

* **Delete.** Click the trash can at the top right to remove a QR from your vault. This has the same effect as removing a QR using the "Edit" button on the main page.
* **Label.** Edit the text field immediately next to the Lifehash to change the name for a QR. This metadata is only for your use, to help you recognize the QR. Be sure to click "Save" after editing the label.
* **Type.** Edit the text field immediately next to the "Type:" to change the category of a QR. If **QR Tool** recognizes a QR's type (such as a 2FA seed or an SSKR shard, it will set this automatically, but otherwise you'll want to set this by hand. Setting and maintaining consistent categories for your QRs will help you to sort them. 

### Exporting QR Data

You can export QR data from the QR view page. There are either two or three options.

* **QR Export.** Select the export arrow next to the QR to export the QR directly via Airdrop, Messages, Mail, or any number of applications on your phone. Ideally, you will be able to export a QR directly to whatever program you want to use it on, but otherwise sending it via a messaging system will usually help you to transfer it.
* **Text Export.** Alternatively, you can just export the text encoded in the QR: select the export arrow next to the text.
* **UR Conversion.** Many QRs are stored as [Uniform Resources](https://github.com/BlockchainCommons/Research/blob/master/papers/bcr-2020-005-ur.md), a Blockchain Commons specification for encoding typed data, in particular to make it efficient for use in QRs. For data not stored as URs, click "convert to UR". (A limited number of crypto-related data types are available for conversion.)

If you want to export a QR code to another app on your phone, and there is not a specific export function, another methodology is to take a screenshot of the QR view, with the QR code, which will save it to front of your photo roll. You can then go to the QR import function on the other app, load it in via camera, and you should see that same landscape icon to allow you to import it from your camera roll. It'll be easy to find because it was just saved. Afterward, you should _remove the screenshot from your camera roll_, so that you are not storing your QR code insecurely.

## For More Info

If you have questions, comments, feature requests, or bug reports, please visit our [Gordian Discussion area](https://github.com/BlockchainCommons/Gordian/discussions) and write us a message!

