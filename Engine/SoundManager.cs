using System;
using System.Collections.Generic;
using System.IO;
using Microsoft.Xna.Framework.Audio;
using AxiomPlayground.Modding;
using in254.Core;

namespace in254.Engine;

public sealed class SoundManager
{
    private static readonly SoundManager _instance = new();
    public static SoundManager Instance => _instance;
    private readonly LoggerBaseCore _logger = new();

    private static readonly string AUDIO_FOLDER = "Audio/";

    // modId → (soundName → SoundEffect)
    private readonly Dictionary<string, Dictionary<string, SoundEffect>> _sounds
        = new(StringComparer.OrdinalIgnoreCase);

    // Reference counting: modId → (soundName → refCount)
    private readonly Dictionary<string, Dictionary<string, int>> _refCounts
        = new(StringComparer.OrdinalIgnoreCase);

    // Track active instances for cleanup
    private readonly List<SoundEffectInstance> _activeInstances = [];

    // Dedicated BGM channel
    private SoundEffectInstance _bgmInstance;
    private string _bgmCurrentName;
    private string _bgmCurrentModId;

    private float _masterVolume = 1.0f;

    private SoundManager() { }

    /// <summary>
    /// Load a .wav sound file from a mod's Audio/ folder.
    /// </summary>
    public void LoadSound(string soundName, string modId, string relativePath)
    {
        if (string.IsNullOrWhiteSpace(soundName))
            throw new ArgumentException("[SoundManager] soundName cannot be empty.");

        if (!_sounds.TryGetValue(modId, out var modSounds))
        {
            modSounds = new Dictionary<string, SoundEffect>(StringComparer.OrdinalIgnoreCase);
            _sounds[modId] = modSounds;
        }

        if (!_refCounts.TryGetValue(modId, out var modRefs))
        {
            modRefs = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
            _refCounts[modId] = modRefs;
        }

        if (modSounds.ContainsKey(soundName))
        {
            modRefs[soundName] = modRefs.GetValueOrDefault(soundName) + 1;
            return; // already loaded, just added a reference
        }

        string modFolder = ModManager.Instance.GetModFolderPath(modId);
        string fullPath = Path.Combine(modFolder, AUDIO_FOLDER, relativePath);

        if (!File.Exists(fullPath))
            throw new LocalizedErrorCore<FileNotFoundException>(
                "system.soundManager.soundFileNotFound", fullPath);

        using var stream = File.OpenRead(fullPath);
        var sound = SoundEffect.FromStream(stream);

        modSounds[soundName] = sound;
        modRefs[soundName] = 1;
        Console.WriteLine($"[SoundManager] Loaded sound '{soundName}' from mod '{modId}' ({relativePath}).");
    }

    /// <summary>
    /// Play a named sound. Returns the instance for further control (stop, etc).
    /// </summary>
    public SoundEffectInstance Play(string modId, string soundName, float volume = 1f, float pitch = 0f, bool loop = false)
    {
        if (!_sounds.TryGetValue(modId, out var modSounds) ||
            !modSounds.TryGetValue(soundName, out var sound))
        {
            Console.WriteLine($"[SoundManager] Sound '{soundName}' not found in mod '{modId}'.");
            return null;
        }

        var instance = sound.CreateInstance();
        instance.Volume = Math.Clamp(volume * _masterVolume, 0f, 1f);
        instance.Pitch = Math.Clamp(pitch, -1f, 1f);
        instance.IsLooped = loop;
        instance.Play();

        _activeInstances.Add(instance);
        return instance;
    }

    /// <summary>
    /// Play a sound once (fire and forget).
    /// </summary>
    public void PlayOnce(string modId, string soundName, float volume = 1f, float pitch = 0f)
    {
        if (!_sounds.TryGetValue(modId, out var modSounds) ||
            !modSounds.TryGetValue(soundName, out var sound))
            return;

        SoundEffect.MasterVolume = _masterVolume;
        sound.Play(Math.Clamp(volume, 0f, 1f), Math.Clamp(pitch, -1f, 1f), 0f);
    }

    /// <summary>
    /// Check if a sound is loaded.
    /// </summary>
    public bool HasSound(string modId, string soundName)
    {
        return _sounds.TryGetValue(modId, out var modSounds) &&
               modSounds.ContainsKey(soundName);
    }

    /// <summary>
    /// Set master volume (0.0 to 1.0).
    /// </summary>
    public void SetMasterVolume(float volume)
    {
        _masterVolume = Math.Clamp(volume, 0f, 1f);
    }

    /// <summary>
    /// Clean up finished instances. Call from Update().
    /// </summary>
    public void Update()
    {
        for (int i = _activeInstances.Count - 1; i >= 0; i--)
        {
            if (_activeInstances[i].State == SoundState.Stopped)
            {
                _activeInstances[i].Dispose();
                _activeInstances.RemoveAt(i);
            }
        }
    }

    /// <summary>
    /// Play a looping BGM track. Stops any currently playing BGM first.
    /// Won't restart if the same track is already playing.
    /// </summary>
    public void PlayBGM(string modId, string soundName, float volume = 0.3f)
    {
        // Skip if same track already playing
        if (_bgmInstance != null && _bgmInstance.State == SoundState.Playing &&
            _bgmCurrentName == soundName && _bgmCurrentModId == modId)
            return;

        StopBGM();

        if (!_sounds.TryGetValue(modId, out var modSounds) ||
            !modSounds.TryGetValue(soundName, out var sound))
        {
            Console.WriteLine($"[SoundManager] BGM '{soundName}' not found in mod '{modId}'.");
            return;
        }

        _bgmInstance = sound.CreateInstance();
        _bgmInstance.Volume = Math.Clamp(volume * _masterVolume, 0f, 1f);
        _bgmInstance.IsLooped = true;
        _bgmInstance.Play();
        _bgmCurrentName = soundName;
        _bgmCurrentModId = modId;

        Console.WriteLine($"[SoundManager] BGM playing: '{soundName}'");
    }

    /// <summary>
    /// Stop the currently playing BGM.
    /// </summary>
    public void StopBGM()
    {
        if (_bgmInstance != null)
        {
            _bgmInstance.Stop();
            _bgmInstance.Dispose();
            _bgmInstance = null;
            _bgmCurrentName = null;
            _bgmCurrentModId = null;
        }
    }

    /// <summary>
    /// Decrement refCount for a sound. Disposes when refCount reaches 0.
    /// </summary>
    public void Release(string modId, string soundName)
    {
        if (!_refCounts.TryGetValue(modId, out var modRefs) ||
            !modRefs.TryGetValue(soundName, out var count))
            return;

        count--;
        if (count <= 0)
        {
            if (_bgmCurrentModId == modId && _bgmCurrentName == soundName)
                StopBGM();
            if (_sounds.TryGetValue(modId, out var modSounds) &&
                modSounds.TryGetValue(soundName, out var sound))
            {
                sound.Dispose();
                modSounds.Remove(soundName);
            }
            modRefs.Remove(soundName);
            Console.WriteLine($"[SoundManager] Released sound '{soundName}' from mod '{modId}' (disposed).");
        }
        else
        {
            modRefs[soundName] = count;
        }
    }

    /// <summary>Backward-compat alias for Release.</summary>
    public void UnloadSound(string modId, string soundName) => Release(modId, soundName);

    /// <summary>
    /// Nuclear option: zero all refCounts and dispose everything for a mod.
    /// </summary>
    public void UnloadAllForMod(string modId)
    {
        if (_bgmCurrentModId == modId) StopBGM();
        if (_sounds.TryGetValue(modId, out var modSounds))
        {
            foreach (var kvp in modSounds) kvp.Value.Dispose();
            modSounds.Clear();
        }
        if (_refCounts.TryGetValue(modId, out var modRefs))
            modRefs.Clear();
        Console.WriteLine($"[SoundManager] Unloaded all sounds for mod '{modId}'.");
    }

    /// <summary>
    /// Stop all playing sounds (SFX + BGM).
    /// </summary>
    public void StopAll()
    {
        StopBGM();

        foreach (var instance in _activeInstances)
        {
            instance.Stop();
            instance.Dispose();
        }
        _activeInstances.Clear();
    }
}
