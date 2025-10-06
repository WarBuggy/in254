export class DataLoader {
    // Main function to process one mod item
    static processModItem(input) {
        const { modName, item, modData, modHistory, } = input || {};
        const { dataType, name, addPayloadToArray, payload } = item || {};

        try {
            DataLoader.validateModItem({ item });
            const pathArray = [dataType, ...name.split(".")];
            // Get existing node in modData
            const existing = pathArray.reduce((obj, key) => obj?.[key], modData);

            // Merge or append payload into modData
            let newValue;
            if (addPayloadToArray && Array.isArray(existing)) {
                if (!Array.isArray(payload)) {
                    newValue = [...existing, payload]; // append single value
                } else {
                    newValue = [...existing, ...payload]; // append payload array
                }
            } else if (existing && !Array.isArray(existing) && !Array.isArray(payload)) {
                // Merge objects
                newValue = DataLoader.mergeObjects({ target: existing, source: payload, }).target;
            } else {
                // Replace otherwise
                newValue = payload;
            }
            DataLoader.setNested({ modData, pathArray, value: newValue });

            // Insert into modHistory and recursively add payload properties
            const { current: leafHistoryNode, } =
                DataLoader.ensureNodePath({ node: modHistory, pathArray, modName });
            DataLoader.addPayloadToHistory({ node: leafHistoryNode, payload, modName, });

            console.log(`[DataLoader] ${taggedString.dataLoaderSuccessful(dataType, name, modName)}`);
        } catch (e) {
            console.error(`[DataLoader] ${taggedString.dataLoaderFailed(dataType, name, modName, e)}`);
        }
    }

    // Recursive merge for objects
    static mergeObjects(input) {
        const { target, source, } = input;
        for (const key of Object.keys(source)) {
            if (source[key] && typeof source[key] === "object" &&
                // Only recursively merge plain objects; skip arrays to avoid treating them as objects
                !Array.isArray(source[key]) && target[key]
                && typeof target[key] === "object" && !Array.isArray(target[key])
            ) {
                DataLoader.mergeObjects({ target: target[key], source: source[key], });
            } else {
                target[key] = source[key];
            }
        }
        return { target, };
    }

    // Utility to set nested value in modData
    static setNested(input) {
        const { modData, pathArray, value, } = input;
        let current = modData;
        for (let i = 0; i < pathArray.length - 1; i++) {
            const nodeName = pathArray[i];
            if (!(nodeName in current)) current[nodeName] = {};
            current = current[nodeName];
        }
        current[pathArray[pathArray.length - 1]] = value;
    }

    // Recursively add history nodes for payload properties
    static addPayloadToHistory(input) {
        const { node, payload, modName, } = input;
        for (const [key, value] of Object.entries(payload)) {
            const { current: nextChildren, } =
                DataLoader.ensureNodePath({ node, pathArray: [key], modName, });
            if (value && typeof value === "object" && !Array.isArray(value)) {
                DataLoader.addPayloadToHistory({ node: nextChildren, payload: value, modName, });
            }
        }
    }

    // Ensure intermediate nodes exist in modHistory and add modName to history
    static ensureNodePath(input) {
        const { node, pathArray, modName, } = input;
        let current = node;
        for (const key of pathArray) {
            if (!(key in current)) current[key] = { history: [], children: {} };
            if (modName && !current[key].history.includes(modName)) {
                current[key].history.push(modName);
            }
            current = current[key].children;
        }
        return { current, };
    }

    // Validate that required properties exist and are of correct type
    static validateModItem(input) {
        const { item, } = input;
        const requiredKeys = ["dataType", "name", "payload"];
        const missingKeyList = requiredKeys.filter((key) => !(key in item));
        if (missingKeyList.length > 0) {
            throw new Error(`${taggedString.dataLoaderErrorItemMissingProperty(missingKeyList.join(", "))}`);
        }

        if (typeof item.dataType !== "string") {
            throw new Error(`${taggedString.dataLoaderErrorPropertyMustBeString('dataType')}`);
        }

        if (typeof item.name !== "string") {
            throw new Error(`${taggedString.dataLoaderErrorPropertyMustBeString('name')}`);
        }

        // Ensure payload is either object or array
        if (
            !(
                (typeof item.payload === "object" && !Array.isArray(item.payload) && item.payload !== null) ||
                Array.isArray(item.payload)
            )
        ) {
            throw new Error(`${taggedString.dataLoaderErrorInvalidPayload('payload')}`);
        }

        // If payload is null (rare), default to empty object
        if (item.payload === null) {
            item.payload = {};
        }
    }

    static getModDataValue(input) {
        const { modData, pathString, } = input;
        if (!modData || !pathString) return undefined;

        const keys = pathString.split('.');
        let current = modData;
        for (const key of keys) {
            if (current[key] === undefined) return undefined;
            current = current[key];
        }
        return { current, };
    }

    /* CONSIDER TO REMOVE
    // Retrieve hierarchical history for a node (with payload properties)
    static getHierarchicalHistory({ modHistory, dataType, name }) {
        const pathArray = [dataType, ...name.split(".")];
        let current = modHistory[dataType];
        if (!current) return null;

        const buildHierarchy = (node, pathIndex) => {
            const result = { history: [...node.history], children: {} };
            if (pathIndex === pathArray.length - 1) return result;

            const nextKey = pathArray[pathIndex + 1];
            if (node.children && node.children[nextKey]) {
                result.children[nextKey] = buildHierarchy(node.children[nextKey], pathIndex + 1);
            }
            return result;
        };

        return { [dataType]: buildHierarchy(current, 0) };
    }

    // Retrieve full hierarchical history for a node and all its nested children
    static getFullHierarchicalHistory({ modHistory, dataType, name }) {
        const pathArray = [dataType, ...name.split(".")];
        let current = modHistory[dataType];
        if (!current) return null;

        // Recursive traversal for children
        const traverseNode = (node) => {
            const result = { history: [...node.history] };
            if (node.children && Object.keys(node.children).length > 0) {
                result.children = {};
                for (const [childKey, childNode] of Object.entries(node.children)) {
                    result.children[childKey] = traverseNode(childNode);
                }
            }
            return result;
        };

        // Walk along the path first
        for (let i = 1; i < pathArray.length; i++) {
            const key = pathArray[i];
            if (!current.children || !current.children[key]) return null;
            current = current.children[key];
        }

        return { [dataType]: traverseNode(current) };
    }
    */
}

/* REQUIREMENT
✅ Updated Requirements
1. Dual storage

modData holds the actual values (payload).

modHistory holds the lifecycle of each node.

2. Existence

Every node must exist in both modData and modHistory.

Every node always has a history array, even if it contains only one item (the creator) and even if the node has no children.

3. History format

History is an array of mod names:

history: ["ModA", "ModB", "ModC"]


Interpretation:

The first mod in the array is the creator.

All subsequent mods are modifiers.

Nodes are never removed.

Each node independently tracks its own history.

New: Every property inside a node’s payload (including nested objects) is also represented as a node in modHistory, with its own history array.

4. Node creation

The first mod that defines the node adds its name to the history array.

Intermediate nodes created automatically also get their own history arrays with the first mod that introduced them.

New: Payload properties that are objects or arrays are recursively converted into nodes in modHistory with the first mod as their creator.

5. Overwriting / Modifying

Explicit / Non-Cascade Overwrite: Overwriting a node only affects that node. Children remain untouched.

If a mod overwrites an existing node:

Append its name to the history array.

Log a warning:

Warning: Mod "ModX" overwrote biome.forest.spawnRules.wolf


Modifying a payload property (or its nested properties) updates the history array for that property node.

6. Intermediate nodes

When creating forest.spawnRules.wolf, intermediate nodes (forest, spawnRules) are auto-created in both modData and modHistory.

Each intermediate node has its own history array.

The first mod that introduces an intermediate node is the first element of its history array.

7. Input format for processing a mod file

modName is external to the mod JS file; it is passed along when processing.

Mod JS file example:

export default {
  modData: [
    {
      dataType: "biome",               // required
      name: "forest.spawnRules.wolf",  // required (dot path)
      payload: {                       // required
        type: "number",
        data: {
          default: 5,
          min: 0,
          max: 10,
          step: 1
        },
        description: "Spawn rate for wolves",
        tooltip: "Adjust this value to control wolf spawn frequency"
      },
      addPayloadToArray: true          // optional
    }
  ]
};


Processing call:

processModItem({ modName: "ModA", item: { ... } });


Properties NOT part of payload: dataType, name, addPayloadToArray.

Everything else (wrapped under payload) → stored in modData.

8. Array handling

Optional property: addPayloadToArray: true | false.

If true:

If existing value in modData is an array → append the payload.

If payload is an array → append all elements individually.

If existing value is not an array → overwrite with the payload.

If false (default):

Payload replaces the existing value, regardless of type.

History: Each append counts as a modification (mod name added to the history array if not already present).

9. Retrieval of history

Given a path (e.g., "forest.spawnRules.wolf") and dataType ("biome"), return an object tree showing the history array for all nodes including payload properties and nested objects.

Example:

{
  biome: {
    history: ["ModA"],
    forest: {
      history: ["ModA"],
      spawnRules: {
        history: ["ModA"],
        wolf: {
          history: ["ModA"],
          type: { history: ["ModA"] },
          data: {
            history: ["ModA"],
            default: { history: ["ModA"] },
            min: { history: ["ModA"] },
            max: { history: ["ModA"] },
            step: { history: ["ModA"] }
          },
          description: { history: ["ModA"] },
          tooltip: { history: ["ModA"] }
        }
      }
    }
  }
}


✅ Key updates since last version:

All actual content is under payload.

Required fields: dataType, name, payload.

Optional: addPayloadToArray.

This eliminates confusion around "data" vs special properties.
*/