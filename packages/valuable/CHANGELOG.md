## 1.3.0

 - **FEAT**: Built-in transformation for Listenable to Valuable. ([50cf6eb7](https://github.com/Azramis/valuable/commit/50cf6eb72da37e1403813c9e8aa1c7bbd6d5874b))
 - **FEAT**: Enhance ValuableCallback with async executions. ([eeb3e344](https://github.com/Azramis/valuable/commit/eeb3e344c0b1aebf53a231292fefaec10952d292))

# CHANGELOG

## 1.2.0

- **FIX**: markNeedsBuild when update for ValuableWidget ([#27](https://github.com/Azramis/valuable/issues/27)).
- **FIX**: dart format.
- **FEAT**: enhance futurevaluable and streamvaluable ([#29](https://github.com/Azramis/valuable/issues/29)).

## 1.1.0

- **REFACTOR**: Add melos management ([#25](https://github.com/Azramis/valuable/issues/25)).
- **FIX**: markNeedsBuild called during building.
- **FEAT**: add undoToInitial and redoToCurrent.

## [1.0.0] - 02/11/2022

- 1.0.0 release ! 🎉🎉🎉
- Add ``HistorizedValuable`` feature
- Add ``ValuableLinker`` feature
- Add a ``def`` extension method on ``ValuableWatcher`` to manage nullable _Valuable_
- Enhance the README.md

## [0.2.2+1] - 26/10/2022

- Fixes to pub.dev score

## [0.2.2] - 26/10/2022

- Fixes to clean watched Valuable
- Fix to provide a ``ValuableContext`` on ``ValuableWidget``
- Add a ``Valuable.listenable`` to link a Valuable to ``ValueListenable``
- Add a ``map`` method on ``Valuable`` to transform ``Output`` type to ``Other``

## [0.2.1] - 06/06/2022

- Add a fresh new ValuableWidget which provide a build method with a ValuableWatcher as parameter
- Downgrade Flutter framework minimum version to 2.0.0 to provide larger compatibility
- Move on FVM

## [0.2.0] - 21/05/2022

- Upgrade Flutter framework minimum version to 3.0.0
- Upgrade Dart framework minimum version to 2.15.0

## [0.1.2] - 04/03/2022

- Fix an issue that avoid StatefulValuable to provide correct current value
- Update linter in example, and support windows

## [0.1.1] - 03/03/2022

- Fix warnings  
- Mechamisms to avoid reevaluating values too often  
- Fix issue with generic type on ValuableWatcher  

## [0.1.0+1] - 26/11/2021

- Empty .pubignore to gain pub points on pub.dev

## [0.1.0] - 26/11/2021

- Fix version to null-safety
- Add .pubignore
- Listed to pub.dev

## [0.1.0-nullsafety] - 19/03/2021

- **BETA** Migration to null-safety

## [0.0.4+2] - 18/03/2021

- Fix an issue with a wrong transitive type on ValuableParentWatcher typedef

## [0.0.4+1] - 24/02/2021

- Add export operations.dart to library

## [0.0.4] - 19/01/2021

- Add comments
- Remove useless classes (like `StatefulValuableBool`) and move the method in extensions
- Extension to manage `Valuable<List>`

## [0.0.3+1] - 08/12/2020

Fix null selector and setState that didn't be called

## [0.0.3] - 03/12/2020

Licensing

## [0.0.2] - 03/12/2020

Change uploader

## [0.0.1] - 03/12/2020

First version -> incomplete
