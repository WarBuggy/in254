// using System.Collections.Generic;
// using in254.Mod;

// namespace in254.Core;

// public class GameObject
// {
//     // One mod -> one data container
//     private readonly Dictionary<ModId, Dictionary<string, object>> _modData = [];

//     /// <summary>
//     /// Returns the current mod's data container.
//     /// This is what Lua sees as `obj.modData`
//     /// </summary>
//     internal Dictionary<string, object> GetCurrentModData()
//     {
//         var modId = ModContextManager.Instance.Current.ModId;
//         return GetOrCreateModData(modId);
//     }

//     /// <summary>
//     /// Returns a specific mod's data container.
//     /// This is what Lua sees as `obj.modData["OtherMod"]`
//     /// </summary>
//     internal Dictionary<string, object> GetModData(ModId modId)
//     {
//         return GetOrCreateModData(modId);
//     }

//     private Dictionary<string, object> GetOrCreateModData(ModId modId)
//     {
//         if (!_modData.TryGetValue(modId, out var data))
//         {
//             data = new Dictionary<string, object>();
//             _modData[modId] = data;
//         }

//         return data;
//     }
// }
