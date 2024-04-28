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

    ['MENU__ITEM'] = 'Items',
    ['MENU__ITEM__DESC'] = 'Use this item to take care of your plant',

    ['MENU_PROCESSING'] = 'Proccessing',

    ['MENU__UNKNOWN__INGREDIANT'] = 'Unknown Ingrediant',
    ['MENU__INGREDIANT__DESC'] = 'You need %g of this ingrediant',

    ['MENU__TABLE__PROCESS'] = 'Process Drugs',
    ['MENU__TABLE__PROCESS__DESC'] = 'Start processing drugs',

    ['MENU__TABLE__REMOVE'] = 'Remove Table',
    ['MENU__TABLE__REMOVE__DESC'] = 'Get this table back',

    ['MENU__SELL'] = 'Sell',
    ['MENU__SELL__DEAL'] = 'Deal',
    ['MENU__SELL__DESC'] = 'Sell %s (x%g) for $%g',

    ['MENU__SELL__ACCEPT'] = 'Accept offer',
    ['MENU__SELL__ACCEPT__DESC'] = 'Accept the current offer',

    ['MENU__SELL__REJECT'] = 'Reject offer',
    ['MENU__SELL__REJECT__DESC'] = 'Reject the current offer',

    ['NOTIFICATION__IN__VEHICLE'] = 'You can´t do this in a Vehicle',
    ['NOTIFICATION__CANT__PLACE'] = 'You can´t do this here',
    ['NOTIFICATION__CANCELED'] = 'Canceled...',
    ['NOTIFICATION__NO__ITEMS'] = 'You have no items to take care of this plant',

    ['NOTIFICATION__NO__AMOUNT'] = 'You need to enter an amount',

    ['NOTIFICATION__MISSING__INGIDIANT'] = 'You don´t have all ingredients',
    ['NOTIFICATION__SKILL__SUCCESS'] = 'You have processed on drug',
    ['NOTIFICATION__PROCESS__FAIL'] = 'You faild to process the drug',

    ['NOTIFICATION__CALLING__COPS'] = 'The buyer is calling the police!',
    ['NOTIFICATION__MAX__PLANTS'] = 'Please take care of your current plants first',
    ['NOTIFICATION__NOT__INTERESTED'] = 'Buyer is not interested to buy now!',
    ['NOTIFICATION__ALLREADY__SPOKE'] = 'You already spoke with this local',
    ['NOTIFICATION__NO__DRUGS'] = 'You have nothing that the person wants',
    ['NOTIFICATION__TO__LONG'] = 'You wasted time so the person left',
    ['NOTIFICATION__OFFER__REJECTED'] = 'You rejected the offer',  
    ['NOTIFICATION__SOLD__DRUG'] = "You recieved $%g",
    ['NOTIFICATION__SELL__FAIL'] = 'You could not sell your %g!',
    ['NOTIFICATION__NO__ITEM__LEFT'] = 'You do not have any %g to sell!',

    ['NOTIFICATION__DRUG__NO__EFFECT'] = 'This drug has no effect',
    ['NOTIFICATION__DRUG__ALREADY'] = 'You are already under the influence of a drug.',

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
    ['TARGET__SELL__LABEL'] = 'Talk'
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