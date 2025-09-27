$(function() { // Equivalent to document.ready
    const $plantTitleElement = $('#plantTitle');
    const $growthProgressBar = $('#growthProgressBar');
    const $growthValue = $('#growthValue');
    const $healthProgressBar = $('#healthProgressBar');
    const $healthValue = $('#healthValue');
    const $waterProgressBar = $('#waterProgressBar');
    const $waterValue = $('#waterValue');
    const $fertilizerProgressBar = $('#fertilizerProgressBar');
    const $fertilizerValue = $('#fertilizerValue');

    const $waterButton = $('#waterButton');
    const $fertilizeButton = $('#fertilizeButton');
    const $destroyButton = $('#destroyButton');
    const $harvestButton = $('#harvestButton');

    const $itemListPanel = $('#itemListPanel');
    const $plantUI = $('#plantUI');

    let currentLanguage = 'de'; // Default language
    let translations = {}; // Will hold loaded translations

    /**
     * Sends a message to the FiveM client.
     * Uses jQuery's $.post for NUI callbacks.
     * @param {string} type The type of message (e.g., 'waterPlant', 'harvestPlant').
     * @param {object} data The data to send with the message.
     */
    function sendNuiCallback(type, data = {}) {
        $.post(`https://your_resource_name/${type}`, JSON.stringify(data), function(resp) {
            // Callback from FiveM, if needed
            console.log('NUI Callback response:', resp);
        });
    }

    /**
     * Updates the plant's title.
     * @param {string} title The new title for the plant.
     */
    function updatePlantTitle(title) {
        $plantTitleElement.text(title);
    }

    /**
     * Updates a progress bar and its value.
     * @param {jQuery} $progressBar The jQuery progress bar element.
     * @param {jQuery} $valueElement The jQuery value display element.
     * @param {number} value The new percentage value (0-100).
     */
    function updateProgressBar($progressBar, $valueElement, value) {
        value = Math.max(0, Math.min(100, value)); // Ensure value is between 0 and 100
        $progressBar.css('width', `${value}%`);
        $valueElement.text(`${value}%`);
    }

    /**
     * Sets the enabled/disabled state of a button.
     * @param {jQuery} $button The jQuery button element.
     * @param {boolean} enable True to enable, false to disable.
     */
    function setButtonEnabled($button, enable) {
        $button.prop('disabled', !enable);
    }

    /**
     * Loads translations from the JSON file.
     * @param {string} lang The language to load.
     */
    async function loadTranslations(lang) {
        try {
            const response = await fetch('translations.json');
            const data = await response.json();
            translations = data;
            setLanguage(lang); // Apply translations immediately after loading
        } catch (error) {
            console.error('Error loading translations:', error);
        }
    }

    /**
     * Applies translations to the UI elements.
     * @param {string} lang The language to apply.
     */
    function setLanguage(lang) {
        currentLanguage = lang;
        $('[data-translate]').each(function() {
            const key = $(this).data('translate');
            if (translations[currentLanguage] && translations[currentLanguage][key]) {
                $(this).text(translations[currentLanguage][key]);
            }
        });
    }

    /**
     * Shows the item list panel with provided items.
     * @param {Array<object>} items An array of objects: [{id: 'item_id', name: 'Item Name'}]
     * @param {string} actionType 'water' or 'fertilize'
     */
    function showItemList(items, actionType) {
        $itemListPanel.empty(); // Clear previous items
        if (items.length === 0) {
            $itemListPanel.text(translations[currentLanguage]?.no_items_found || 'No matching items found.');
            $itemListPanel.removeClass('hidden');
            return;
        }

        items.forEach(item => {
            const $button = $('<button>')
                .addClass('item-button')
                .text(translations[currentLanguage] ? translations[currentLanguage][item.id] || item.name : item.name)
                .on('click', () => {
                    sendNuiCallback(`${actionType}ItemUsed`, { itemId: item.id });
                    hideItemList(); // Hide list after selection
                });
            $itemListPanel.append($button);
        });
        $itemListPanel.removeClass('hidden');
    }

    /**
     * Hides the item list panel.
     */
    function hideItemList() {
        $itemListPanel.addClass('hidden');
    }

    // Event Listeners for Buttons using jQuery
    $waterButton.on('click', () => {
        // This would typically come from FiveM, e.g., via an NUI message.
        // For demonstration, let's use dummy data.
        const waterItems = [
            { id: 'water_bottle', name: 'Wasserflasche' },
            { id: 'watering_can', name: 'Gießkanne' }
        ];
        showItemList(waterItems, 'water');
    });

    $fertilizeButton.on('click', () => {
        const fertilizeItems = [
            { id: 'liquid_fertilizer', name: 'Flüssigdünger' },
            { id: 'water_fertilizer', name: 'Wasserdünger' }
        ];
        showItemList(fertilizeItems, 'fertilize');
    });

    $destroyButton.on('click', () => {
        sendNuiCallback('destroyPlant');
        hideItemList();
    });

    $harvestButton.on('click', () => {
        sendNuiCallback('harvestPlant');
        hideItemList();
    });

    // Listener for messages from FiveM using jQuery's event system
    window.addEventListener('message', (event) => {
        const data = event.data; // This is the data sent from the FiveM client

        if (data.type === 'updatePlantUI') {
            updatePlantTitle(data.plantName);
            updateProgressBar($growthProgressBar, $growthValue, data.growth);
            updateProgressBar($healthProgressBar, $healthValue, data.health);
            updateProgressBar($waterProgressBar, $waterValue, data.water);
            updateProgressBar($fertilizerProgressBar, $fertilizerValue, data.fertilizer);

            // Update button states
            setButtonEnabled($waterButton, data.canWater);
            setButtonEnabled($fertilizeButton, data.canFertilize);
            setButtonEnabled($destroyButton, data.canDestroy);
            setButtonEnabled($harvestButton, data.canHarvest);

            // If the item list was open, hide it if the action is no longer possible
            if (data.canWater === false || data.canFertilize === false) {
                hideItemList();
            }

        } else if (data.type === 'showPlantUI') {
            $plantUI.css('display', 'flex');
            hideItemList(); // Initially hide item list
        } else if (data.type === 'hidePlantUI') {
            $plantUI.css('display', 'none');
            hideItemList();
        } else if (data.type === 'setUILanguage') {
            setLanguage(data.lang);
        } else if (data.type === 'updateUIColors') {
            $(':root').css({
                '--primary-bg-color': data.primaryBgColor,
                '--secondary-bg-color': data.secondaryBgColor,
                '--text-color': data.textColor,
                '--accent-color': data.accentColor,
                '--progress-bar-bg': data.progressBarBg,
                '--button-hover-bg': data.buttonHoverBg,
                '--disabled-button-color': data.disabledButtonColor
            });
        }
    });

    // Initial load of translations and hide UI on load
    loadTranslations(currentLanguage);
    $plantUI.css('display', 'none'); // Hide UI initially, FiveM will show it when needed


    // For local testing (remove in FiveM build)
    // You can uncomment this to test UI updates directly in a browser
    
    setTimeout(() => {
        window.postMessage({
            type: 'updatePlantUI',
            plantName: 'My Awesome Weed',
            growth: 75,
            health: 80,
            water: 60,
            fertilizer: 90,
            canWater: true,
            canFertilize: true,
            canDestroy: true,
            canHarvest: false // Example: Cannot harvest yet
        }, '*');
        window.postMessage({ type: 'showPlantUI' }, '*');
    }, 1000);

    // Simulate language change
    setTimeout(() => {
        window.postMessage({ type: 'setUILanguage', lang: 'en' }, '*');
    }, 5000);

    // Simulate color change
    setTimeout(() => {
        window.postMessage({
            type: 'updateUIColors',
            primaryBgColor: '#333333',
            secondaryBgColor: '#444444',
            textColor: '#eeeeee',
            accentColor: '#00bcd4', // Teal
            progressBarBg: '#666666',
            buttonHoverBg: '#4db6ac',
            disabledButtonColor: '#777777'
        }, '*');
    }, 8000);
    
});