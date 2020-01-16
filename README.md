# Word Quiz (iOS)

With such great game, you can check how sharp you memory is in terms of java sintax!
Here you can play, typing all Java's special words whitin 5 minutes time.
If you can manage to remember and type all 50 of them, well, you such a java ninja!


## Requirements

For runing our game, you'll have to have:

- Xcode 9 or later.

- Swift 5.0 or later.

- iOS 10.3 or later.

### Installing

As there are no third part libraries, you can run by just pressing CMD + R in the simulator of your choice


## Coding style

We're curently using the **MVVM - Model View View Model** pattern for our entire architecture.

#### View Controllers:
Are is used to display data and manage any view related animations/actions/gestures that will be passed to view model to make decisions of what to do next.

#### View Models
It is used to provide formatted data to the view and should be able to accomodate the complete view.
It is also where business rule's related methods will be.

##### Delegates:
Using the delegate pattern to communicate information between controller and view model.

## Authors

**Lucas Teixeira Carletti**
