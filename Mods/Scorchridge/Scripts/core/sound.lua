-- ============================================
-- Scorchridge — Sound Module
-- SFX helpers + per-scene sound loading
-- ============================================

local SFX = {}

-- Convenience wrappers
function SFX.Click()      Sound.Play("click", 0.5) end
function SFX.Hover()      Sound.Play("hover", 0.3) end
function SFX.Advance()    Sound.Play("advance", 0.6) end
function SFX.Pickaxe()    Sound.Play("pickaxe", 0.4) end
function SFX.Eat()        Sound.Play("eat", 0.5) end
function SFX.Rest()       Sound.Play("rest", 0.3) end
function SFX.QuotaMet()   Sound.Play("quota_met", 0.7) end
function SFX.QuotaFail()  Sound.Play("quota_fail", 0.6) end
function SFX.Event()      Sound.Play("event", 0.6) end
function SFX.Drug()       Sound.Play("drug", 0.4) end

-- BGM management
local currentBGM = nil

function SFX.PlayBGM(name)
    if currentBGM == name then return end
    currentBGM = name
    Sound.PlayBGM(name, 0.25)
end

function SFX.StopBGM()
    currentBGM = nil
    Sound.StopBGM()
end

function SFX.UpdateBGM(phase)
    if phase == "work" then
        SFX.PlayBGM("bgm_work")
    elseif phase == "rest" or phase == "downtime" then
        SFX.PlayBGM("bgm_rest")
    else
        SFX.PlayBGM("bgm_ambient")
    end
end

-- Load all gameplay sounds
function SFX.LoadGameplaySounds()
    Sound.Load("click", "click.wav")
    Sound.Load("hover", "hover.wav")
    Sound.Load("advance", "advance.wav")
    Sound.Load("pickaxe", "pickaxe.wav")
    Sound.Load("eat", "eat.wav")
    Sound.Load("rest", "rest.wav")
    Sound.Load("quota_met", "quota_met.wav")
    Sound.Load("quota_fail", "quota_fail.wav")
    Sound.Load("event", "event.wav")
    Sound.Load("drug", "drug.wav")
    Sound.Load("bgm_ambient", "bgm_ambient.wav")
    Sound.Load("bgm_work", "bgm_work.wav")
    Sound.Load("bgm_rest", "bgm_rest.wav")
    print("[Scorchridge] Gameplay sounds loaded.")
end

-- Load minimal menu/UI sounds
function SFX.LoadMenuSounds()
    Sound.Load("click", "click.wav")
    Sound.Load("hover", "hover.wav")
    print("[Scorchridge] Menu sounds loaded.")
end

return SFX
