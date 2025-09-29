
# Roadmap - RateMyBowl

## Demo 1 (Oct. 27)

- [ ] Get everyone set up with a working development environment
- [ ] Flutter
    - [ ] Get everyone familiar with Flutter basics (Excellent tutorial [here](https://youtu.be/1xipg02Wu8s))
    - [ ] Learn how to [make Flutter talk to Firebase](https://firebase.google.com/docs/flutter/setup)
    - [ ] Find a secrets management system so we aren't publishing access keys
    - [ ] Create Login Screen
        - [ ] Account creation screen
    - [ ] Create Map Screen (using [this library](https://pub.dev/packages/flutter_map))
        - [ ] Find how to render custom widgets to it
- [ ] Get basic login through Firebase integration
    - [ ] Learn some Firebase, get everyone access to it
    - [ ] How to create user accounts for application
    - [ ] Learn Firebase's built-in user account storage features
- [ ] UI design mockups/drawings
- [ ] SQL data relationship model

## Demo 2 (Nov. 17)

- [ ] SQL
    - [ ] Define structure of data to be stored on the server
- [ ] Flutter
    - [ ] Create Account Screen (after logged in, use it to manage profile info)
    - [ ] Create Welcome/Home Screen
        - [ ] Report what you're doing
    - [ ] Create (basic) Reviewing Screen
        - [ ] Rating up to 5 stars
        - [ ] Notes about the restroom (text)
        - [ ] Settle on a list of other bathroom attributes to allow the user to input
        - [ ] "no restroom here" report

## Demo 3 (Dec. 8)

- [ ] General data aggregation feature
    - [ ] "Report hazard" feature (closed, facilities not working)
        - [ ] Out of toilet paper
    - [ ] How will it work? Where/when will the question get asked?
    - [ ] Type of sink (automatic with a sensor or manual with knobs)
    - [ ] Hand-drying options (air blower, paper towel, or both)
    - [ ] Does it require a key (i.e. from the receptionist's desk)
- [ ] List view for restrooms near you
- [ ] Full test coverage (within reason)
- [ ] Filtering for what restrooms the map is showing the user
- [ ] Gender-aware data
    - What if the men's and women's restrooms are separated? Does it count as one?

## Stretch Goals

- [ ] Selectively load restroom information where the map is focused to (just getting all the data from the server is not great)
- [ ] Google Account integration (could actually be easy)
- [ ] Use Google Maps Flutter library: https://pub.dev/packages/google_maps_flutter
- [ ] Restroom ownership and alert system
- [ ] "I clogged this toilet" point system
- [ ] Web support

## What this app will NOT have

- Posts, feed to scroll on
- Image uploading
- Moderation of data, reporting system

