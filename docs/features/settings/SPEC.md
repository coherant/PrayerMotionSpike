# App Settings — Feature Spec

Source of truth for the **Settings** screen.
Use this file to define layout, components, interactions, and data before building.

## 0. Overview

This is the settings for the entire application.

---

## 1. Layout

See docs/features/settings/settings.html

---

## 2. Settings sections

# Prayer Alerts
DESCRIPTION: Notifcations setting for all prayers -> A common screen which gives the user the ability to select the different recitation for each prayer 

Layout and taxonomy of settings
-[setting] Sahoor ending reminder (on/off) -> used in the month of ramadan and is used to alert (via notification) 15 mins before sahoor.
-[list] For each Prayer (e.g. Fajr, Asr etc)
    --[option] Pre-Adhan remider (on/off) [label] Gentle knock reminder 30 minutes before the prayer starts
    --[list] all available recitations
        ---[item] Recitation audio file

# Advanced
DESCRIPTION: Prayer time adjustments off the master prayer times table 
-[list] Prayer names (e.g. Fajr)
    --[list-item] Fajr
        Decription: only onne is selectable
        [setting] Normal > use the master time
        [setting] 1.5 hours before sunrise
    --[list-item] Sunrise
        Decription: only onne is selectable
        [setting] Normal > use the master time
        [setting] Doha
    --[list-item] Asr
        Decription: only onne is selectable
        [setting] Shafi
        [setting] Standard (Shafi, Maliki, Hanbali)
        [setting] Hanafi
    --[list-item] Isha
        Decription: only onne is selectable
        [setting] Normal > use the master time
        [setting] 1.5 hours before Maghrib
        [setting] 2 hours before Maghrib
    --[list-item] Qiyam (on/off) --> this adds the Qiyam time to the list of prayers on the Prayer Times Screen at the end of the prayers list.
-[setting] Prayer Time Adjustments
    --[list-item] Fajr
        Decription: scrollable wheel default = 0
        [setting] offset
    --[list-item] Dhuhr
        Decription: scrollable wheel default = 0
        [setting] offset
    --[list-item] Asr
        Decription: scrollable wheel default = 0
        [setting] offset
    --[list-item] Maghrib
        Decription: scrollable wheel default = 0
        [setting] offset
    --[list-item] Isha
        Decription: scrollable wheel default = 0
        [setting] offset
-[setting] Adjust Hijri Days
    Decription: scrollable wheel default = 0
    [setting] offset
-[setting] Language
    -[list] Languages
        --[list-item] Turkish
        --[list-item] Arabic
        --[list-item] Bengali
        --[list-item] Indonesian / Bahasa
        --[list-item] Australian (default)
        --[list-item] Deutsche
        --[list-item] Francais
        --[list-item] Malay
-[function] Rate this app -> Connects to the apple ratings system

## Prayer Calculation Method
DESCRIPTION: Prayer time calculation method
-[list] All the popular calculation methods
    --[list-item] Muslim world league
    --[list-item] Egypitan general authority
    --[list-item] Islamic University, Karachi


---

## 3. States

<!-- Default, loading, empty, error states -->

---

## 4. Interactions

<!-- Tap, toggle, navigation behaviour -->

---

## 5. Data model

<!-- What is persisted, where (UserDefaults / UserPreferences), and how -->

---

## 6. Navigation

<!-- How the user reaches this screen and where they go from it -->
