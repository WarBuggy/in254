using System;
using MoonSharp.Interpreter;
using AxiomPlayground.Scripting;
using AxiomPlayground.Scripting.LuaBindings;

namespace in254.Engine.LuaBindings
{
    public sealed class SoundLuaBinding : LuaBindingBase
    {
        public override void Register(Script luaScript)
        {
            ArgumentNullException.ThrowIfNull(luaScript);

            Table soundTable = new(luaScript);

            // Sound.Load(soundName, relativePath)
            // Loads a .wav from the calling mod's Audio/ folder.
            // e.g. Sound.Load("click", "click.wav")
            soundTable["Load"] = (Action<string, string>)((soundName, relativePath) =>
            {
                string modId = ScriptManager.Instance.CurrentExecutingModId;
                SoundManager.Instance.LoadSound(soundName, modId, relativePath);
                SceneManager.Instance.TrackResource(modId, SceneManager.ResourceType.Sound, soundName);
            });

            // Sound.Play(soundName)
            // Sound.Play(soundName, volume)
            // Sound.Play(soundName, volume, pitch)
            // Sound.Play(soundName, volume, pitch, loop)
            soundTable["Play"] = (Action<string, DynValue, DynValue, DynValue>)(
                (soundName, volumeDyn, pitchDyn, loopDyn) =>
            {
                string modId = ScriptManager.Instance.CurrentExecutingModId;
                float volume = (float)(volumeDyn.IsNil() ? 1.0 : volumeDyn.Number);
                float pitch = (float)(pitchDyn.IsNil() ? 0.0 : pitchDyn.Number);
                bool loop = !loopDyn.IsNil() && loopDyn.Boolean;

                if (loop)
                    SoundManager.Instance.Play(modId, soundName, volume, pitch, true);
                else
                    SoundManager.Instance.PlayOnce(modId, soundName, volume, pitch);
            });

            // Sound.Has(soundName) → bool
            soundTable["Has"] = (Func<string, bool>)(soundName =>
            {
                string modId = ScriptManager.Instance.CurrentExecutingModId;
                return SoundManager.Instance.HasSound(modId, soundName);
            });

            // Sound.SetVolume(volume) — master volume 0.0 to 1.0
            soundTable["SetVolume"] = (Action<double>)(volume =>
            {
                SoundManager.Instance.SetMasterVolume((float)volume);
            });

            // Sound.PlayBGM(soundName, volume)
            soundTable["PlayBGM"] = (Action<string, DynValue>)((soundName, volumeDyn) =>
            {
                string modId = ScriptManager.Instance.CurrentExecutingModId;
                float volume = (float)(volumeDyn.IsNil() ? 0.3 : volumeDyn.Number);
                SoundManager.Instance.PlayBGM(modId, soundName, volume);
            });

            // Sound.StopBGM()
            soundTable["StopBGM"] = (Action)(() =>
            {
                SoundManager.Instance.StopBGM();
            });

            // Sound.StopAll()
            soundTable["StopAll"] = (Action)(() =>
            {
                SoundManager.Instance.StopAll();
            });

            // Sound.Unload(soundName)
            soundTable["Unload"] = (Action<string>)(soundName =>
            {
                string modId = ScriptManager.Instance.CurrentExecutingModId;
                SoundManager.Instance.UnloadSound(modId, soundName);
            });

            // Sound.UnloadAll()
            soundTable["UnloadAll"] = (Action)(() =>
            {
                string modId = ScriptManager.Instance.CurrentExecutingModId;
                SoundManager.Instance.UnloadAllForMod(modId);
            });

            luaScript.Globals["Sound"] = soundTable;
        }
    }
}
