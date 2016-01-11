# GammaThingy
Changes screen gamma on iOS, no jailbreak required

RIP official sideload f.lux (https://justgetflux.com/sideload/) 😢

With the new Night Shift feature on iOS 9.3, this is pretty much obsolete.

## Important Information
This project is in no way associated with f.lux.

I talked with Britta Gustafson about this idea/project at jailbreakcon 2015, and she felt that I should contact the developers of f.lux before publicly releasing anything to do with changing the screen temperature. I know they don't have a monopoly on it, but they care very deeply about what they work on and have poured their lives into a piece of software which they feels improves the lives of others (which it does). Aside from that, f.lux has a home on practically every jailbroken phone, and I wouldn't want to hurt the feelings of anyone so important to the jailbreaking community by making a cheap knockoff of their work just for fun. Besides all that, this is not nearly as complex or well-designed as the actual f.lux application and most likely will never come close. The developers of f.lux have spent a lot of time perfecting what they do.

## License
I don't know which license matches this so I'm going to write it out. You can do what you want with the code, but do not distribute compiled copies of the app, especially on mass download sites.

## Compiling
This can't be compiled for or run in the simulator so don't try it, it won't work. If you get errors make sure all frameworks are linked correctly, especially IOKit and IOMobileFramebuffer.

## Troubleshooting

If you find the display glitching while GammaThingy is enabled, ensure that you have disabled ```Reduce White Point``` in iOS ```Settings / General / Accessibility / Increase Contrast```

## URL Scheme Support

GammaThingy supports URL schemes to switch the orangeness.  
For the base URL ```gammathingy://orangeness/switch``` those (optional) parameters are available:
* ```enable``` to toggle orangeness on / off (for values ```1```/```0```), if not provided, the orangeness is just switched
* ```x-source``` to supply a protocol to open after switching orangeness (e.g. to switch back to another app)
* ```close``` to make the app quit after the action was executed if its value is ```1```

Examples:  
```gammathingy://orangeness/switch?enable=1&x-source=prefs``` enables orangeness and then *attempts* to open the Preferences.app  
```gammathingy://orangeness/switch?close=1``` switches orangeness and closes the app afterwards
