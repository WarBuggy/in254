class Shared {
  static STORAGE_KEY_LIST = {
    LANGUAGE: 'language',
  };

  static EMITTER_SIGNAL = {
    OVERLAY_VISIBLE: 'overlayVisible',
    OVERLAY_CLOSED: 'overlayClosed',
  };

  static BUNKER_TYPE = {
    CELL: 'cell',
    CONTROL_ROOM: 'control room',
    ELEVATOR: 'elevator',
  };

  static MOD_STRING = {
    REGISTRATION_MODE: {
      BEFORE: 'before',
      AFTER: 'after',
      REPLACE: 'replace',
      NEW_METHOD: 'newMethod',
    },
    RESERVED_MOD_NAME_LIST: ['base'],
    MOD_DIR_LOCATION: {
      BASE: '../../../mod/',
    },
    BASE_TAG_NAME: 'mod',
    ABOUT_XML: {
      FILE_NAME: 'about.xml',
      NAME: 'name',
      VERSION: 'version',
      AUTHOR: 'author',
      HOOKS: 'hooks',
      HOOK: 'hook',
    },
    SETTING_XML: {
      FILE_NAME: 'setting.xml',
      LIST: 'list',
      LIST_ENTRY: 'listEntry',
      MOD_NAME: 'modName',
      DIR_NAME: 'dirName',
    },
    MOD_DATA_TYPE: {
      COLONY_DATA: 'colony data',
      ANIMATION_DATA: 'animation data',
      PLAYER_DATA: 'player data',
    },
  };

  /**
   * Clamps a numeric value between a minimum and maximum bound.
   *
   * @param {number} input.value - The value to be clamped.
   * @param {number} input.min - The lower bound.
   * @param {number} input.max - The upper bound.
   *
   * @returns {number} - The clamped value, guaranteed to be between min and max.
   */
  static clamp(input) {
    const value = Math.min(input.max, Math.max(input.min, input.value));
    return { value, };
  }

  /**
   * Creates an HTML element with optional id, class, and parent attachment.
   * Defaults to a <div> if no tag is provided.
   *
   * @param {string} [input.tag='div'] - The tag name of the element to create (e.g., 'div', 'span').
   * @param {string} [input.id] - Optional ID to assign to the element.
   * @param {HTMLElement} [input.parent] - Optional parent element to append the new element to.
   * @param {string} [input.class] - Optional CSS class(es) to assign to the element.
   * @returns {HTMLElement} The newly created HTML element.
   */
  static createHTMLComponent(input) {
    const { id, tag, parent, className, type, } = input;
    let elementTag = 'div';
    if (tag) {
      elementTag = tag;
    }
    const component = document.createElement(elementTag);
    if (id) {
      component.id = id;
    }
    if (parent) {
      parent.appendChild(component);
    }
    if (className) {
      component.className = className;
    }
    if (type) {
      component.type = type;
    }
    return { component, };
  }

  static async loadImage(input) {
    const { src, } = input;
    const img = new Image();
    img.src = src;
    try {
      await img.decode();
      return img;
    } catch (err) {
      console.warn(`${taggedString.generalFailedToLoadImage(src, err)}`);
      return null;
    }
  }
}