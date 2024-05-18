--[[ Cartoon Sounds
      by Coldblooded and Grimmier
      Description: This script plays custom sounds for various events in game.
      Original concept and Code by Coldblooded
      He wrote the C code and initial implimentation.
      I took this and ran with it adding a GUI and more sounds / events.
      Comes with Customizable sounds and volume settings. configurable in the config window.
      You can add any .wav file to the sound folder and it will be available to use by name.
      You can also sort your sounds folder by sub folders and reference that folder instead of the default.
      This is useful if you want to have different sounds for different characters.
      In the future I may add the ability to add custom events from the GUI.
]]

local mq = require('mq')
local ffi = require("ffi")

-- C code definitions
ffi.cdef[[
   int sndPlaySoundA(const char *pszSound, unsigned int fdwSound);
   uint32_t waveOutSetVolume(void* hwo, uint32_t dwVolume);
]]

local winmm = ffi.load("winmm")

local SND_ASYNC = 0x0001
local SND_LOOP = 0x0008
local SND_FILENAME = 0x00020000
local flags = SND_FILENAME + SND_ASYNC

-- Main Settings
local RUNNING = true
local path = mq.TLO.Lua.Dir().."\\cartoonSounds\\sounds\\"
local configFile = mq.configDir .. '/CartoonSounds.lua'
local settings, defaults = {}, {}
local timerA, timerB = os.time(), os.time()
local openConfigGUI = false
local tmpTheme = 'default'

defaults = {
   doHit = true,
   doBonk = true,
   doLvl = true,
   doDie = true,
   doHP = true,
   doAA = true,
   doFizzle = true,
   volFizzle = 25,
   volAA = 10,
   volHit = 2,
   volBonk = 5,
   volLvl = 100,
   volDie = 100,
   volHP = 20,
   lowHP = 50,
   theme = 'default',
   Pulse = 1,
   Sounds = {
      default = {
         soundHit = "Hit.wav",
         soundBonk = "Bonk.wav",
         soundLvl = "LevelUp.wav",
         soundDie = "Die.wav",
         soundLowHp = "lowHP.wav",
         soundAA = "AA.wav",
         soundFizzle = 'Fizzle.wav',
      }
   }
   
}

---comment Check to see if the file we want to work on exists.
---@param name string -- Full Path to file
---@return boolean -- returns true if the file exists and false otherwise
local function File_Exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

-- Function to play sound allowing for simultaneous plays
local function playSound(filename)
   if File_Exists(filename) then
      winmm.sndPlaySoundA(filename, flags)
      else
      printf('\aySound File \aw[\ag%s\aw]\ao is MISSING!!\ax', filename)
   end
end

-- Function to set volume (affects all sounds globally)
local function setVolume(volume)
   if volume < 0 or volume > 100 then
      error("Volume must be between 0 and 100")
   end
   local vol = math.floor(volume / 100 * 0xFFFF)
   local leftRightVolume = bit32.bor(bit32.lshift(vol, 16), vol) -- Set both left and right volume
   winmm.waveOutSetVolume(nil, leftRightVolume)
end

-- Simplified for clarity: Event sound handling
local function eventSound(_, event, vol)
   if not settings["do" .. event] then return end
   local sound = settings.Sounds[settings.theme]["sound" .. event]
   if sound and settings["do" .. event] then
      local fullPath = string.format("%s%s\\%s", path, settings.theme, sound)
      setVolume(vol)
      playSound(fullPath)
   end
end

-- Settings
local function loadSettings()
   
   if not File_Exists(configFile) then
      mq.pickle(configFile, defaults)
      loadSettings()
      else
      -- Load settings from the Lua config file
      settings = dofile(configFile)
      if not settings then
         settings = {}
         settings = defaults
      end
   end
   tmpTheme = settings.theme or 'default'
   local newSetting = false
   for k,v in pairs(defaults) do
      if settings[k] == nil then
         settings[k] = v
         newSetting = true
      end
   end
   
   for k,v in pairs(settings.Sounds[settings.theme]) do
      if not File_Exists(string.format("%s%s\\%s",path, settings.theme, v)) then
         settings[k] = false
         printf("\aySound file %s missing!!\n\tTurning %s \arOFF",string.format("%s%s\\%s",path, settings.theme, v),k)
      end
   end
   
   if newSetting then mq.pickle(configFile, settings) end
end

-- Print Help
local function helpList(type)
   local timeStamp = mq.TLO.Time()
   if type == 'help' then
      printf('\aw%s \ax:: \ayCartoon Sounds Help\ax', timeStamp)
      printf('\aw%s \ax:: \at /sillysounds hit     \t \ag Toggles sound on and off for your hits\ax', timeStamp)
      printf('\aw%s \ax:: \at /sillysounds bonk    \t \ag Toggles sound on and off for you being hit\ax', timeStamp)
      printf('\aw%s \ax:: \at /sillysounds fizzle    \t \ag Toggles sound on and off for your spell fizzles\ax', timeStamp)
      printf('\aw%s \ax:: \at /sillysounds lvl     \t \ag Toggles sound on and off for when you Level\ax', timeStamp)
      printf('\aw%s \ax:: \at /sillysounds aa      \t \ag Toggles sound on and off for You gain AA\ax', timeStamp)
      printf('\aw%s \ax:: \at /sillysounds die     \t \ag Toggles sound on and off for your Deaths\ax', timeStamp)
      printf('\aw%s \ax:: \at /sillysounds hp      \t \ag Toggles sound on and off for Low Health\ax', timeStamp)
      printf('\aw%s \ax:: \at /sillysounds hp 1-100\t \ag Sets PctHPs to toggle low HP sound, 1-100\ax', timeStamp)
      printf('\aw%s \ax:: \ayCartoon Sounds Volume Control\ax', timeStamp)
      printf('\aw%s \ax:: \at /sillysounds hit 0-100\t \ag Sets Volume for hits 0-100 accepts decimal values\ax', timeStamp)
      printf('\aw%s \ax:: \at /sillysounds bonk 0-100\t\ag Sets Volume for bonk 0-100 accepts decimal values\ax', timeStamp)
      printf('\aw%s \ax:: \at /sillysounds fizzle 0-100\t \ag Sets Volume for fizzle 0-100 accepts decimal values\ax', timeStamp)
      printf('\aw%s \ax:: \at /sillysounds lvl 0-100 \t\ag Sets Volume for lvl 0-100 accepts decimal values\ax', timeStamp)
      printf('\aw%s \ax:: \at /sillysounds aa 0-100 \t\ag Sets Volume for AA 0-100 accepts decimal values\ax', timeStamp)
      printf('\aw%s \ax:: \at /sillysounds die 0-100 \t\ag Sets Volume for die 0-100 accepts decimal values\ax', timeStamp)
      printf('\aw%s \ax:: \at /sillysounds volhp 0-100 \t\ag Sets Volume for lowHP 0-100 accepts decimal values\ax', timeStamp)
      printf('\aw%s \ax:: \ayCartoon Sounds Other\ax', timeStamp)
      printf('\aw%s \ax:: \at /sillysounds help      \t\ag Brings up this list\ax', timeStamp)
      printf('\aw%s \ax:: \at /sillysounds config    \t\ag Opens Config GUI Window\ax', timeStamp)
      printf('\aw%s \ax:: \at /sillysounds show      \t\ag Prints out the current settings\ax', timeStamp)
      printf('\aw%s \ax:: \at /sillysounds quit      \t\ag Exits the script\ax', timeStamp)
      elseif type == 'show' then
      printf('\aw%s \ax:: \ayCartoon Current Settings\ax', timeStamp)
      for k, v in pairs(settings) do
         
         if k ~= 'Sounds' then
            printf("\aw%s \ax:: \at%s \ax:\ag %s\ax",timeStamp, k, tostring(v))
         end
      end
   end
end

-- Binds
local function bind(...)
   local newSetting = false
   local args = {...}
   local key = args[1]
   local value = tonumber(args[2], 10) or nil
   if key == nil then helpList('help') return end
   if string.lower(key) == 'hit' then
      if value ~= nil then
         settings.volHit = value or 50
         printf("setting %s Volume to %s",key , tostring(settings.volHit))
         playSound(string.format("%s%s\\%s",path, settings.theme, settings.Sounds[settings.theme].soundHit))
         else
         settings.doHit = not settings.doHit
         printf("setting %s to %s",key ,tostring(settings.doHit))
      end
      newSetting = true
      elseif string.lower(key) == 'bonk' then
      if value ~= nil then
         settings.volBonk = value or 50
         printf("setting %s Volume to %d",key , tostring(settings.volBonk))
         playSound(string.format("%s%s\\%s",path, settings.theme, settings.Sounds[settings.theme].soundBonk))
         else
         settings.doBonk = not settings.doBonk
         printf("setting %s to %s",key ,tostring(settings.doBonk))
      end
      newSetting = true
      elseif string.lower(key) == 'aa' then
      if value ~= nil then
         settings.volAA = value or 50
         printf("setting %s Volume to %d",key , tostring(settings.volAA))
         playSound(string.format("%s%s\\%s",path, settings.theme, settings.Sounds[settings.theme].soundAA))
         else
         settings.doAA = not settings.doAA
         printf("setting %s to %s",key ,tostring(settings.doAA))
      end
      newSetting = true
      elseif string.lower(key) == 'config' then
      openConfigGUI = true
      elseif string.lower(key) == 'lvl' then
      if value ~= nil then
         settings.volLvl = value or 50
         printf("setting %s Volume to %d",key , tostring(settings.volLvl))
         playSound(string.format("%s%s\\%s",path, settings.theme, settings.Sounds[settings.theme].soundLvl))
         else
         settings.doLvl = not settings.doLvl
         printf("setting %s to %s",key ,tostring(settings.doLvl))
      end
      newSetting = true
      elseif string.lower(key) == 'die' then
      if value ~= nil then
         settings.volDie = value or 50
         printf("setting %s Volume to %d",key , tostring(settings.volDie))
         playSound(string.format("%s%s\\%s",path, settings.theme, settings.Sounds[settings.theme].soundDie))
         else
         settings.doDie = not settings.doDie
         printf("setting %s to %s",key ,tostring(settings.doDie))
      end
      newSetting = true
      elseif string.lower(key) == 'hp' then
      if value ~= nil then
         settings.lowHP = value or 0
         printf("setting %s to %s",key ,tostring(value))
         else
         settings.doHP = not settings.doHP
         printf("setting %s to %s",key ,tostring(settings.doHP))
      end
      newSetting = true
      elseif string.lower(key) == 'volhp' then
      if value ~= nil then
         settings.volHP = value or 50
         printf("setting %s Volume to %d",key , tostring(settings.volHP))
         playSound(string.format("%s%s\\%s",path, settings.theme, settings.Sounds[settings.theme].soundLowHp))
         newSetting = true
      end
      elseif string.lower(key) == 'help' or key == nil then
      helpList('help')
      elseif string.lower(key) == 'show' then
      helpList(key)
      elseif string.lower(key) == 'quit' or key == nil then
      RUNNING = false
   end
   if newSetting then mq.pickle(configFile, settings) end
end

-- UI
local function Config_GUI(open)
   if not openConfigGUI then return end
   
   open, openConfigGUI = ImGui.Begin("Cartoon Sounds Config##CartoonSounds", open, bit32.bor(ImGuiWindowFlags.None, ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.NoCollapse))
   if not openConfigGUI then
      openConfigGUI = false
      open = false
      ImGui.End()
      return open
   end
   
   tmpTheme = ImGui.InputText("Sound Folder Name##FolderName", tmpTheme)
   ImGui.SameLine()
   if ImGui.Button('Update##CartoonSounds') then
      if settings.Sounds[tmpTheme] == nil then
         settings.Sounds[tmpTheme] = {
            soundHit = "Hit.wav",
            soundBonk = "Bonk.wav",
            soundLvl = "LevelUp.wav",
            soundDie = "Die.wav",
            soundLowHp = "lowHP.wav"
         }
      end
      settings.theme = tmpTheme
      mq.pickle(configFile, settings)
      loadSettings()
   end
   --- tmp vars to change ---
   local tmpSndHit = settings.Sounds[settings.theme].soundHit or 'Hit.wav'
   local tmpVolHit = settings.volHit or 100
   local tmpDoHit = settings.doHit
   local tmpSndBonk = settings.Sounds[settings.theme].soundBonk or 'Bonk.wav'
   local tmpVolBonk = settings.volBonk or 100
   local tmpDoBonk = settings.doBonk
   local tmpSndFizzle = settings.Sounds[settings.theme].soundFizzle or 'Fizzle.wav'
   local tmpVolFizzle = settings.volFizzle or 100
   local tmpDoFizzle = settings.doFizzle
   local tmpSndLvl = settings.Sounds[settings.theme].soundLvl or 'LevelUp.wav'
   local tmpVolLvl = settings.volLvl or 100
   local tmpDoLvl = settings.doLvl
   local tmpSndAA = settings.Sounds[settings.theme].soundAA or 'AA.wav'
   local tmpVolAA = settings.volAA or 100
   local tmpDoAA = settings.doAA
   local tmpSndDie = settings.Sounds[settings.theme].soundDie or 'Die.wav'
   local tmpVolDie = settings.volDie or 100
   local tmpDoDie = settings.doDie
   local tmpSndHP = settings.Sounds[settings.theme].soundLowHp or 'lowHp.wav'
   local tmpVolHP = settings.volHP or 100
   local tmpDoHP = settings.doHP or false
   local tmpLowHp = settings.lowHP or 50
   local tmpPulse = settings.Pulse or 1
   
   if ImGui.BeginTable('Settings_Table##CartoonSounds',4,ImGuiTableFlags.None) then
      ImGui.TableSetupColumn('##Toggle_CartoonSounds', ImGuiTableColumnFlags.WidthAlwaysAutoResize)
      ImGui.TableSetupColumn('##File_CartoonSounds', ImGuiTableColumnFlags.WidthAlwaysAutoResize)
      ImGui.TableSetupColumn('##Vol_CartoonSounds', ImGuiTableColumnFlags.WidthAlwaysAutoResize)
      ImGui.TableSetupColumn('##SaveBtn_CartoonSounds', ImGuiTableColumnFlags.WidthAlwaysAutoResize)
      ImGui.TableNextRow()
      ImGui.TableNextColumn()
      tmpDoHit = ImGui.Checkbox('Hit Alert##CartoonSounds', tmpDoHit)
      if tmpDoHit ~= settings.doHit then
         settings.doHit = tmpDoHit
      end
      ImGui.TableNextColumn()
      ImGui.SetNextItemWidth(70)
      tmpSndHit = ImGui.InputText('Filename##HITSND', tmpSndHit)
      if tmpSndHit ~= settings.Sounds[settings.theme].soundHit then
         settings.Sounds[settings.theme].soundHit = tmpSndHit
      end
      ImGui.TableNextColumn()
      ImGui.SetNextItemWidth(100)
      tmpVolHit = ImGui.InputFloat('Volume##HITVOL',tmpVolHit, 0.1)
      if tmpVolHit ~= settings.volHit then
         settings.volHit = tmpVolHit
      end
      ImGui.TableNextColumn()
      if ImGui.Button("Test and Save##HITALERT") then
         setVolume(settings.volHit)
         playSound(string.format("%s%s\\%s",path, settings.theme, settings.Sounds[settings.theme].soundHit))
         mq.pickle(configFile, settings)
      end
      ImGui.TableNextRow()
      ImGui.TableNextColumn()
      --- Bonk Alerts ---
      tmpDoBonk = ImGui.Checkbox('Bonk Alert##CartoonSounds', tmpDoBonk)
      if tmpDoBonk ~= settings.doBonk then
         settings.doBonk = tmpDoBonk
      end
      ImGui.TableNextColumn()
      ImGui.SetNextItemWidth(70)
      tmpSndBonk = ImGui.InputText('Filename##BonkSND', tmpSndBonk)
      if tmpSndBonk ~= settings.Sounds[settings.theme].soundBonk then
         settings.Sounds[settings.theme].soundBonk = tmpSndBonk
      end
      ImGui.TableNextColumn()
      ImGui.SetNextItemWidth(100)
      tmpVolBonk = ImGui.InputFloat('Volume##BonkVOL',tmpVolBonk, 0.1)
      if tmpVolBonk ~= settings.volBonk then
         settings.volBonk = tmpVolBonk
      end
      ImGui.TableNextColumn()
      if ImGui.Button("Test and Save##BonkALERT") then
         setVolume(settings.volBonk)
         playSound(string.format("%s%s\\%s",path, settings.theme, settings.Sounds[settings.theme].soundBonk))
         mq.pickle(configFile, settings)
      end
      --- Spell Fizzle Alerts ---
      ImGui.TableNextRow()
      ImGui.TableNextColumn()
      tmpDoFizzle = ImGui.Checkbox('Fizzle Alert##CartoonSounds', tmpDoFizzle)
      if tmpDoFizzle ~= settings.doFizzle then
         settings.doFizzle = tmpDoFizzle
      end
      ImGui.TableNextColumn()
      ImGui.SetNextItemWidth(70)
      tmpSndFizzle = ImGui.InputText('Filename##FizzleSND', tmpSndFizzle)
      if tmpSndFizzle ~= settings.Sounds[settings.theme].soundFizzle then
         settings.Sounds[settings.theme].soundFizzle = tmpSndFizzle
      end
      ImGui.TableNextColumn()
      ImGui.SetNextItemWidth(100)
      tmpVolFizzle = ImGui.InputFloat('Volume##FizzleVOL',tmpVolFizzle, 0.1)
      if tmpVolFizzle ~= settings.volFizzle then
         settings.volFizzle = tmpVolFizzle
      end
      ImGui.TableNextColumn()
      if ImGui.Button("Test and Save##FizzleALERT") then
         setVolume(settings.volFizzle)
         playSound(string.format("%s%s\\%s",path, settings.theme, settings.Sounds[settings.theme].soundFizzle))
         mq.pickle(configFile, settings)
      end
      
      --- Lvl Alerts ---
      ImGui.TableNextRow()
      ImGui.TableNextColumn()
      
      tmpDoLvl = ImGui.Checkbox('LvlUp Alert##CartoonSounds', tmpDoLvl)
      if settings.doLvl ~= tmpDoLvl then
         settings.doLvl = tmpDoLvl
      end
      ImGui.TableNextColumn()
      ImGui.SetNextItemWidth(70)
      tmpSndLvl = ImGui.InputText('Filename##LvlUpSND', tmpSndLvl)
      if tmpSndLvl ~= settings.Sounds[settings.theme].soundLvl then
         settings.Sounds[settings.theme].soundLvl = tmpSndLvl
      end
      ImGui.TableNextColumn()
      ImGui.SetNextItemWidth(100)
      tmpVolLvl = ImGui.InputFloat('Volume##LvlUpVOL',tmpVolLvl, 0.1)
      if tmpVolLvl ~= settings.volLvl then
         settings.volLvl = tmpVolLvl
      end
      ImGui.TableNextColumn()
      if ImGui.Button("Test and Save##LvlUpALERT") then
         setVolume(settings.volLvl)
         playSound(string.format("%s%s\\%s",path, settings.theme, settings.Sounds[settings.theme].soundLvl))
         mq.pickle(configFile, settings)
      end
      --- AA Alerts ---
      ImGui.TableNextRow()
      ImGui.TableNextColumn()
      
      tmpDoAA = ImGui.Checkbox('AA Alert##CartoonSounds', tmpDoAA)
      if tmpDoAA ~= settings.doAA then
         settings.doAA = tmpDoAA
      end
      ImGui.TableNextColumn()
      ImGui.SetNextItemWidth(70)
      tmpSndAA = ImGui.InputText('Filename##AASND', tmpSndAA)
      if tmpSndAA ~= settings.Sounds[settings.theme].soundAA then
         settings.Sounds[settings.theme].soundAA = tmpSndAA
      end
      ImGui.TableNextColumn()
      ImGui.SetNextItemWidth(100)
      tmpVolAA = ImGui.InputFloat('Volume##AAVOL',tmpVolAA, 0.1)
      if tmpVolAA ~= settings.volAA then
         settings.volAA = tmpVolAA
      end
      ImGui.TableNextColumn()
      if ImGui.Button("Test and Save##AAALERT") then
         setVolume(settings.volAA)
         playSound(string.format("%s%s\\%s",path, settings.theme, settings.Sounds[settings.theme].soundAA))
         mq.pickle(configFile, settings)
      end
      
      --- Death Alerts ---
      ImGui.TableNextRow()
      ImGui.TableNextColumn()
      
      tmpDoDie = ImGui.Checkbox('Death Alert##CartoonSounds', tmpDoDie)
      if settings.doDie ~= tmpDoDie then
         settings.doDie = tmpDoDie
      end
      ImGui.TableNextColumn()
      ImGui.SetNextItemWidth(70)
      tmpSndDie = ImGui.InputText('Filename##DeathSND', tmpSndDie)
      if tmpSndDie ~= settings.Sounds[settings.theme].soundDie then
         settings.Sounds[settings.theme].soundDie = tmpSndDie
      end
      ImGui.TableNextColumn()
      ImGui.SetNextItemWidth(100)
      tmpVolDie = ImGui.InputFloat('Volume##DeathVOL',tmpVolDie, 0.1)
      if tmpVolDie ~= settings.volDie then
         settings.volDie = tmpVolDie
      end
      ImGui.TableNextColumn()
      if ImGui.Button("Test and Save##DeathALERT") then
         setVolume(settings.volDie)
         playSound(string.format("%s%s\\%s",path, settings.theme, settings.Sounds[settings.theme].soundDie))
         mq.pickle(configFile, settings)
      end
      
      --- LOW HP ---
      ImGui.TableNextRow()
      ImGui.TableNextColumn()
      tmpDoHP = ImGui.Checkbox('Low Health Alert##CartoonSounds', tmpDoHP)
      if settings.doHP ~= tmpDoHP then
         settings.doHP = tmpDoHP
      end
      ImGui.TableNextColumn()
      ImGui.SetNextItemWidth(70)
      tmpSndHP = ImGui.InputText('Filename##LowHealthSND', tmpSndHP)
      if tmpSndHP ~= settings.Sounds[settings.theme].soundLowHp then
         settings.Sounds[settings.theme].soundLowHp = tmpSndHP
      end
      ImGui.TableNextColumn()
      ImGui.SetNextItemWidth(100)
      tmpVolHP = ImGui.InputFloat('Volume##LowHealthVOL',tmpVolHP, 0.1)
      if tmpVolHP ~= settings.volHP then
         settings.volHP = tmpVolHP
      end
      ImGui.TableNextColumn()
      if ImGui.Button("Test and Save##LowHealthALERT") then
         setVolume(settings.volHP)
         playSound(string.format("%s%s\\%s",path, settings.theme, settings.Sounds[settings.theme].soundLowHp))
         mq.pickle(configFile, settings)
      end
      ImGui.EndTable()
   end
   tmpLowHp = ImGui.InputInt('Low HP Threshold##LowHealthThresh',tmpLowHp,1)
   if tmpLowHp ~= settings.lowHP then
      settings.lowHP = tmpLowHp
   end
   tmpPulse = ImGui.InputInt('Pulse Delay##LowHealthPulse',tmpPulse,1)
   if tmpPulse ~= settings.Pulse then
      settings.Pulse = tmpPulse
   end
   
   if ImGui.Button('Close') then
      openConfigGUI = false
      mq.pickle(configFile, settings)
   end
   
   ImGui.End()
   
end

-- Main loop
local function mainLoop()
   while RUNNING do
      mq.doevents()
      mq.delay(1)
      if mq.TLO.Me.PctHPs() <= settings.lowHP and mq.TLO.Me.PctHPs() > 1 and settings.doHP then
         timerA = os.time()
         if timerA - timerB > settings.Pulse then
            setVolume(settings.volHP)
            playSound(string.format("%s%s\\%s",path, settings.theme, settings.Sounds[settings.theme].soundLowHp))
            timerB = os.time()
            mq.delay(1)
         end
      end
   end
end

-- Init
local function init()
   helpList('help')
   loadSettings()
   
   -- Event bindings
   mq.event("gained_level", "You have gained a level! Welcome to level #*#", function(line) eventSound(line, 'Lvl', settings.volLvl) end)
   mq.event("hit", "You #*# for #*# of damage.",function(line) eventSound(line, 'Hit', settings.volHit) end)
   mq.event("been_hit", "#*# YOU for #*# of damage.", function(line) eventSound(line, 'Bonk', settings.volBonk) end)
   mq.event("you_died", "You died.", function(line) eventSound(line, 'Die', settings.volDie) end)
   mq.event("you_died2", "You have been slain by#*#", function(line) eventSound(line, 'Die', settings.volDie) end)
   mq.event("gained_aa", "#*#gained an ability point#*#", function(line) eventSound(line, 'AA', settings.volAA) end)
   mq.event("spell_fizzle", "Your#*#spell fizzles#*#", function(line) eventSound(line, 'Fizzle', settings.volFizzle) end)
   
   -- Slash Command Binding
   mq.bind('/sillysounds', bind)
   
   -- Setup Config GUI
   mq.imgui.init('Cartoon Sounds Config', Config_GUI)
   
   mainLoop()
end

init()
