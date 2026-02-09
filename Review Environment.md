Review Environment

Submission ID: 6f032e46-4a56-46f0-816b-c6cdb9465b55
Review date: September 18, 2025
Version reviewed: 1.0


Guideline 5.1.2 - Legal - Privacy - Data Use and Sharing


The app privacy information provided in App Store Connect indicates the app collects data in order to track the user, including Email Address, User ID, and Name. However, the app does not use App Tracking Transparency to request the user's permission before tracking their activity.

Apps need to receive the user’s permission through the AppTrackingTransparency framework before collecting data used to track them. This requirement protects the privacy of users.

Next Steps

Here are three ways to resolve this issue:

- If the app does not currently track, update the app privacy information in App Store Connect. You must have the Account Holder or Admin role to update app privacy information. If you are unable to change the privacy label, reply to this message in App Store Connect, and make sure your App Privacy Information in App Store Connect is up to date before submitting your next update for review.

- If this app does not track on the platform associated with this submission, but tracks on other platforms, notify App Review by replying to the rejection in App Store Connect. You should also reply if this app does not track on the platform associated with this submission but tracks on other Apple platforms this app is available on.

- If the app tracks users on all supported platforms, the app must use App Tracking Transparency to request permission before collecting data used to track. When resubmitting, indicate in the Review Notes where the permission request is located.

Note that if the app behaves differently in different countries or regions, you should provide a way for App Review to review these variations in the app submission. Additionally, these differences should be documented in the Review Notes section of App Store Connect.

Resources

- Tracking is linking data collected from the app with third-party data for advertising purposes, or sharing the collected data with a data broker. Learn more about tracking. 
- See Frequently Asked Questions about the requirements for apps that track users.
- Learn more about designing appropriate permission requests.


Guideline 2.1 - Performance

Issue Description

The app crashed during review. Apps that crash negatively impact users. 

Specifically, your app crashed when we attempted to open the camera for a new profile picture.

Review device details:

- Device type: iPad Air (5th generation) 
- OS version: iPadOS 26.0

Next Steps

Test the app on supported devices to identify crashes and stability issues before resubmitting for review. Crash logs have been attached to help resolve this issue:

1. Fully symbolicate the crash report. See Adding Identifiable Symbol Names to a Crash Report.
2. Match the crash report to a common pattern. Based on the pattern, take specific actions to further investigate the crash. See Identifying the Cause of Common Crashes.
3. Once the root causes of the crash have been identified, make the appropriate changes to the binary to resolve the issue.
4. Test the app on a device to ensure that it runs as expected.

Resources

- For more information on crash reports, see Diagnosing Issues Using Crash Reports and Device Logs.
- For information about testing apps and preparing them for review, see Testing a Release Build.
- To learn about troubleshooting networking issues, see Networking Overview.



Guideline 5.1.1(v) - Data Collection and Storage

Issue Description

The app supports account creation but does not include an option to initiate account deletion. Apps that support account creation must also offer account deletion to give users more control of the data they've shared while using an app.

Follow these requirements when updating an app to support account deletion:

- Only offering to temporarily deactivate or disable an account is insufficient.
- If users need to visit a website to finish deleting their account, include a link directly to the website page where they can complete the process.
- Apps may include confirmation steps to prevent users from accidentally deleting their account. However, only apps in highly-regulated industries may require users to use customer service resources, such as making a phone call or sending an email, to complete account deletion.

Next Steps

Update the app to support account deletion. If the app already supports account deletion, reply to App Review in App Store Connect and identify where to locate this feature.

If the app is unable to offer account deletion or needs to provide additional customer service flows to facilitate and confirm account deletion, either because the app operates in a highly-regulated industry or for some other reason, reply to App Review in App Store Connect and provide additional information or documentation. For questions regarding legal obligations, check with legal counsel.

Resources

Review frequently asked questions and learn more about the account deletion requirements.


Guideline 5.1.1 - Legal - Privacy - Data Collection and Storage


The app encourages or directs users to allow the app to access the camera and photo library. Specifically, the app directs the user to grant permission in the following way(s): 

- A custom message appears before the permission request, and the user can close the message and delay the permission request with the Cancelar button. The user should always proceed to the permission request after the message. 

Permission requests give users control of their personal information. It is important to respect their decision about how their data is used.

Next Steps

To resolve this issue, please revise the permission request process in the app to not include an exit button on the message before the permission request.

If necessary, you may provide more information about why you are requesting permission before the request appears. If the user is trying to use a feature in the app that won't function without access to the camera and photo library, you may include a notification to inform the user and provide a link to the Settings app. 

Resources 

- Learn more about data collection and storage requirements in guideline 5.1.1. 
- Learn more about designing appropriate permission requests.

Support

- Reply to this message in your preferred language if you need assistance. If you need additional support, use the Contact Us module.
- Consult with fellow developers and Apple engineers on the Apple Developer Forums.
- Provide feedback on this message and your review experience by completing a short survey