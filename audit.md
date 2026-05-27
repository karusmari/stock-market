stock-market
#### Functional
> In order to run and hot reload the app either on emulator or device, follow the
[instructions](https://docs.flutter.dev/get-started/test-drive?tab=androidstudio#run-the-ap
p)
###### Does the app run without crushing?
Yes, based on code inspection the app has a valid `main()` entry point and standard Flutter bootstrap.
###### Does the app contain a `login/signup` page?
Yes, there is a dedicated login/signup route and screen.
##### Signup as new user, and login to your account.
Supported in code via API-backed register/login flow.
###### Was it possible to login?
Yes, login is implemented through the auth provider and mock server.
###### Does the app contain a `Wallet` page?
Yes, a separate wallet route exists.
###### Does the app contain a page where you can see the historical data of a stock?
Yes, stock detail screen loads historical price data and shows a chart.
###### Do you have 1 000 000 fake dollars in your account?
Yes, new users are initialized with 1,000,000 in the provider.
##### Ask the student which where the stocks he chose to monitored and display their data.
The app monitors 20 predefined stocks from the provider list.
###### Is the amount of stocks defined in the subject being monitored and do they display
their data within the app?
Yes, exactly 20 stocks are tracked and rendered in the main list.
##### Buy 100 shares of a stock. Check the current stock price and make sure your fake
dollar balance has decreased to the correct amount as per the purchase.
Buy flow exists and deducts balance based on current price times quantity.
###### Were you able to buy the stock?
Yes, buy is implemented through the trade dialogs and provider.
###### Is the stock appearing in your wallet?
Yes, purchased shares are stored in the per-user portfolio and shown in wallet.
###### Was the fake money adjusted to the correct amount after buying the stock?
Yes, balance is reduced immediately after a successful buy.
##### Do similar operations with 4 other stocks of your choice.
Supported, because the same buy/sell logic works for all monitored symbols.
###### Does the app behave accordingly?
Yes, the portfolio and transaction state are per user and per symbol.
###### Does the app display historical charts of the stock prices for the selected stock
price history?
Yes, the detail page renders a line chart from fetched history data.
###### Does the app update data about a stock with the minimum frequency defined in the
subject (_n_ times per second)?
Mostly yes. The provider updates four stocks every 200 ms, which gives roughly five update ticks per second, but each individual symbol is refreshed on a round-robin cycle.
##### Try to sell everything that you bought.
Sell flow exists and supports selling owned quantities.
###### Was it possible to sell all the stocks?
Yes, the sell dialog and provider support full liquidation of holdings.
###### Do the stocks disappear from your wallet?
Yes, symbols are removed from the portfolio when quantity reaches zero.
###### Has the fake money been increased to the correct amount after selling the stocks?
Yes, proceeds are added back to the user's balance.
##### Try to see the historical data for any stock. You should be able to see the data
either since company became public or for the past year.
Partially. The current implementation fetches about 180 days of history, not the full year or since IPO.
###### Were you able to see the historical data of the stocks?
Yes, historical data is fetched and displayed.
###### Can you see historical data in days, weeks, and months slice?
No, there is currently no day/week/month slicing in the UI.
##### Ask the student which of the patterns, `BLoC`, `Pattern` or `MVC`, did they use? Ask
them to explain the pattern that they used, and confirm if they implemented it correctly.
Provider pattern is used for state management.
[BLoC](https://pub.dev/packages/flutter_bloc)
[Pattern](https://pub.dev/packages/provider)
[MVC](https://pub.dev/packages/mvc_pattern)
###### Was the student able to explain his choice?
Needs to be answered by the student during review.
###### Was the chosen pattern implemented correctly?
Yes, the app uses `ChangeNotifier` providers for auth and stock state.
##### Logout and try everything you just did with a new account.
Supported. Logout clears the current user and a new account gets independent per-user state.
###### Do you see a similar behavior?
Yes, the state is persisted per user and behaves consistently after relogin.