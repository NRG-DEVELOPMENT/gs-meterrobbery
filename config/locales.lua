Locales = {}

-- English (Default)
Locales['en'] = {
    ['meter_robbery'] = 'Parking Meter Robbery',
    ['rob_meter'] = 'Rob Parking Meter',
    ['robbing_meter'] = 'Robbing parking meter...',
    ['meter_robbed'] = 'You successfully robbed the parking meter!',
    ['meter_failed'] = 'You failed to rob the parking meter!',
    ['meter_empty'] = 'This parking meter is empty!',
    ['police_required'] = 'Not enough police in the city!',
    ['minigame_start'] = 'Breaking into the meter...',
    ['second_minigame_start'] = 'Almost there! Keep going...',
    ['missing_item'] = 'You don\'t have the required items!',
    ['received_money'] = 'You received $%s from the parking meter!',
    ['received_item'] = 'You received %sx %s from the parking meter!',
    ['dispatch_title'] = 'Parking Meter Robbery',
    ['dispatch_desc'] = 'Someone is attempting to rob a parking meter!',
    ['cancel_robbery'] = 'Robbery cancelled!',
    ['meter_broken'] = 'This meter is already broken!',
    ['minigame_failed'] = 'You failed the minigame!',
    ['minigame_success'] = 'You successfully completed the minigame!',
}

-- Current language setting
Config.Language = 'en'

-- Function to get localized text
function _U(str, ...)
    if Locales[Config.Language] and Locales[Config.Language][str] then
        return string.format(Locales[Config.Language][str], ...)
    else
        return string.format(Locales['en'][str], ...)
    end
end