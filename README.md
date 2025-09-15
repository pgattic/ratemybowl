
# Rate My Bowl (Yelp but for Public Restrooms)

*Rest in That Room*™

Everyone has been through the pain of having to use a subpar restroom. It always goes the same way: I walk in, have one look at the bathroom, and think "Dang, I should have gone somewhere else. But what's the point? I'm already here". But NO MORE! Now, with this app, and the help of all who contribute ratings, I will finally be able to rest in that room.

## Summary of features

Just what the name implies. Rate, review, and discover public restrooms on the go! Will allow you to pan around on a map and see all the available restrooms, each displaying their average rating, out of 5 stars. You will also be able to add a restroom to the map, or add a review to an existing one. You will be able to report the following information in each review:

- Overall cleanliness (out of 5 stars)
- Toilet paper quality (out of 5 stars)
- Notes about the restroom (text)

In addition, the following general information will be gathered about each restroom, and asked alongside the reviewing process:

- Type of sink (automatic with a sensor or manual with knobs)
- Hand-drying options (air blower, paper towel, or both)
- Does it require a key (i.e. from the receptionist's desk)

## Roadmap

- [ ] Firebase
    - [ ] How to create user accounts for application
    - [ ] Firebase SQL Relationship map
- [ ] Flutter
    - [ ] Learn how to make it talk to our firebase
    - [ ] Find a secrets management system so we aren't publishing access keys
    - [ ] Determine Flutter Map library
        - [ ] Find how to render custom widgets to it

## Dev Environment

### Nix (with Flakes enabled)

- Ensure an Android emulator or ADB is configured.
- `nix develop`

### Windows

- Follow the [Windows -> Android instructions](https://docs.flutter.dev/get-started/install/windows/mobile) on the Flutter documentation

### MacOS

- Follow the [MacOS -> Android instructions](https://docs.flutter.dev/get-started/install/macos/mobile-android) on the Flutter Documentation

