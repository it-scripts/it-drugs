Locales['en'] = {
    ['MENU_PLANT'] = '%s',
    ['MENU__DEAD_PLANT'] = 'Dead Plant',

    ['MENU__PLANT__LIFE'] = 'Health',
    ['MENU__PLANT__LIFE__META'] = 'The health of the plant, if it reaches 0 the plant will die',
    
    ['MENU__PLANT__STAGE'] = 'Stage',
    ['MENU__PLANT__STAGE__META'] = 'The stage of the plant, if it reaches 100 the plant can be harvested',

    ['MENU__PLANT__FERTILIZER'] = 'Fertilizer',
    ['MENU__PLANT__FERTILIZER__META'] = 'Every plant need nutritions to grow, be sure to fertilize your plant',
    
    ['MENU__PLANT__WATER'] = 'Water',
    ['MENU__PLANT__WATER__META'] = 'Be sure your plant always have some water',

    ['MENU__PLANT__DESTROY'] = 'Destroy',
    ['MENU__PLANT__DESTROY__DESC'] = 'Destroy this plant',

    ['MENU__PLANT__HARVEST'] = 'Harvest',
    ['MENU__PLANT__HARVEST__DESC'] = 'Harvest this plant',

    ['MENU_PROCESSING'] = 'Proccessing',

    ['MENU__UNKNOWN__INGREDIANT'] = 'Unknown Ingrediant',
    ['MENU__INGREDIANT__DESC'] = 'You need %g of this ingrediant',

    ['MENU__TABLE__PROCESS'] = 'Process Drugs',
    ['MENU__TABLE__PROCESS__DESC'] = 'Start processing drugs',

    ['MENU__TABLE__REMOVE'] = 'Remove Table',
    ['MENU__TABLE__REMOVE__DESC'] = 'Get this table back',

    ['NOTIFICATION__IN__VEHICLE'] = 'You can´t do this in a Vehicle',
    ['NOTIFICATION__CANT__PLACE'] = 'You can´t do this here',
    ['NOTIFICATION__CANCELED'] = 'Canceled...',
    ['NOTIFICATION__NO__WATER'] = 'You don´t have any water',
    ['NOTIFICATION__NO__FERTILIZER'] = 'You don´t have any fertilizer',

    ['NOTIFICATION__MISSING__INGIDIANT'] = 'You don´t have all ingredients',
    ['NOTIFICATION__SKILL__SUCCESS'] = 'You have processed on drug',

    ['NOTIFICATION_CALLING_COPS'] = 'The buyer is calling the police!',
    ['NOTIFICATION_NOT_INTERESTED'] = 'Buyer is not interested to buy now!',
    ['NOTIFICATION_ALLREADY_SPOKE'] = 'You already spoke with this local',
    ['NOTIFICATION_SOLD_DRUG'] = "You recieved $%g",
    ['NOTIFICATION_SELL_FAIL'] = 'You could not sell your %g!',
    ['NOTIFICATION_FALSE_DRUG'] = 'Person wanted something else!',
    ['NOTIFICATION_NO_ITEM_LEFT'] = 'You do not have any %g to sell!',
    ['NOTIFICATION_TO_LONG'] = 'You wasted time so the person left',
    ['NOTIFICATION_OFFER_REJECTED'] = 'You rejected the offer',

    ['NOTIFICATION__NO__AMOUNT'] = 'You need to enter an amount',

    ['PROGRESSBAR__SPAWN__PLANT'] = 'Planting...',
    ['PROGRESSBAR__HARVEST__PLANT'] = 'Harvesting...',
    ['PROGRESSBAR__SOAK__PLANT'] = 'Watering...',
    ['PROGRESSBAR__FERTILIZE__PLANT'] = 'Fertilizing...',
    ['PROGRESSBAR__DESTROY__PLANT'] = 'Destroying...',

    ['PROGRESSBAR__PLACE__TABLE'] = 'Placing Table...',
    ['PROGRESSBAR__REMOVE__TABLE'] = 'Removing Table...',
    ['PROGRESSBAR__PROCESS__DRUG'] = 'Processing...',

    ['INTERACTION__PLACING__TEXT'] = '[E] - Place Plant / [G] - Cancel',
    ['INTERACTION__INTERACT_TEXT'] = '[E] - Interact',

    ['INPUT__AMOUNT__HEADER'] = 'Processing',
    ['INPUT__AMOUNT__TEXT'] = 'Amount',
    ['INPUT__AMOUNT__DESCRIPTION'] = 'How many do you want to process?',

    ['TARGET__PLANT__LABEL'] = 'Check Plant',
    ['TARGET__TABLE__LABEL'] = 'Use Table',
}

function _U(string)
	if Locales[Config.Language] == nil then
		return "Language not found"
	end
	if Locales[Config.Language][string] == nil then
		return string
	end
	return Locales[Config.Language][string]
end