--[[
    AIT-QB: English Locale
    Fallback locale
]]

AIT = AIT or {}
AIT.Locales = AIT.Locales or {}

AIT.Locales.en = {
    -- General
    ['loading'] = 'Loading...',
    ['please_wait'] = 'Please wait...',
    ['success'] = 'Success',
    ['error'] = 'Error',
    ['warning'] = 'Warning',
    ['info'] = 'Information',
    ['confirm'] = 'Confirm',
    ['cancel'] = 'Cancel',
    ['accept'] = 'Accept',
    ['decline'] = 'Decline',
    ['yes'] = 'Yes',
    ['no'] = 'No',
    ['close'] = 'Close',
    ['open'] = 'Open',
    ['save'] = 'Save',
    ['delete'] = 'Delete',
    ['edit'] = 'Edit',
    ['add'] = 'Add',
    ['remove'] = 'Remove',
    ['back'] = 'Back',
    ['next'] = 'Next',
    ['previous'] = 'Previous',
    ['search'] = 'Search',
    ['filter'] = 'Filter',
    ['sort'] = 'Sort',
    ['refresh'] = 'Refresh',
    ['unknown'] = 'Unknown',
    ['none'] = 'None',
    ['all'] = 'All',

    -- Money
    ['money_cash'] = 'Cash',
    ['money_bank'] = 'Bank',
    ['money_crypto'] = 'Crypto',
    ['money_received'] = 'You received $%s',
    ['money_removed'] = '$%s was removed',
    ['money_not_enough'] = 'Not enough money',
    ['money_transferred'] = 'You transferred $%s to %s',
    ['money_received_from'] = 'You received $%s from %s',

    -- Character
    ['character_create'] = 'Create Character',
    ['character_select'] = 'Select Character',
    ['character_delete'] = 'Delete Character',
    ['character_first_name'] = 'First Name',
    ['character_last_name'] = 'Last Name',
    ['character_dob'] = 'Date of Birth',
    ['character_gender'] = 'Gender',
    ['character_gender_male'] = 'Male',
    ['character_gender_female'] = 'Female',
    ['character_nationality'] = 'Nationality',

    -- Jobs
    ['job_unemployed'] = 'Unemployed',
    ['job_on_duty'] = 'You are now on duty',
    ['job_off_duty'] = 'You are now off duty',
    ['job_paycheck'] = 'Paycheck: $%s',
    ['job_promoted'] = 'You have been promoted to %s',
    ['job_demoted'] = 'You have been demoted to %s',
    ['job_fired'] = 'You have been fired',
    ['job_hired'] = 'You have been hired as %s',
    ['job_already_on_duty'] = 'You are already on duty',
    ['job_not_on_duty'] = 'You are not on duty',
    ['job_wrong_job'] = 'You don\'t have the right job',
    ['job_wrong_grade'] = 'You don\'t have the required rank',

    -- Inventory
    ['inventory_full'] = 'Inventory is full',
    ['inventory_not_enough'] = 'Not enough items',
    ['inventory_item_received'] = 'Received %sx %s',
    ['inventory_item_removed'] = 'Removed %sx %s',
    ['inventory_item_used'] = 'You used %s',
    ['inventory_item_given'] = 'You gave %sx %s to %s',
    ['inventory_cannot_carry'] = 'You cannot carry this',
    ['inventory_invalid_item'] = 'Invalid item',

    -- Vehicles
    ['vehicle_locked'] = 'Vehicle locked',
    ['vehicle_unlocked'] = 'Vehicle unlocked',
    ['vehicle_no_keys'] = 'You don\'t have the keys',
    ['vehicle_engine_on'] = 'Engine started',
    ['vehicle_engine_off'] = 'Engine stopped',
    ['vehicle_no_fuel'] = 'No fuel',
    ['vehicle_refueling'] = 'Refueling...',
    ['vehicle_refueled'] = 'Vehicle refueled',
    ['vehicle_impounded'] = 'Vehicle impounded',
    ['vehicle_retrieved'] = 'Vehicle retrieved',
    ['vehicle_stored'] = 'Vehicle stored',
    ['vehicle_not_owned'] = 'You don\'t own this vehicle',
    ['vehicle_already_out'] = 'Vehicle is already out',
    ['vehicle_repair'] = 'Repairing vehicle...',
    ['vehicle_repaired'] = 'Vehicle repaired',

    -- Police
    ['police_cuff'] = 'You have been handcuffed',
    ['police_uncuff'] = 'You have been uncuffed',
    ['police_escort'] = 'You are being escorted',
    ['police_escort_stop'] = 'Escort stopped',
    ['police_search'] = 'Searching...',
    ['police_fine'] = 'You received a $%s fine',
    ['police_jail'] = 'You have been jailed for %s months',
    ['police_unjail'] = 'You have been released',
    ['police_wanted'] = 'You are now wanted',
    ['police_not_wanted'] = 'You are no longer wanted',

    -- Medical
    ['medical_dead'] = 'You are dead',
    ['medical_revived'] = 'You have been revived',
    ['medical_healed'] = 'You have been healed',
    ['medical_bleeding'] = 'You are bleeding',
    ['medical_need_help'] = 'You need medical attention',
    ['medical_call_ems'] = 'Call EMS (E)',

    -- Housing
    ['housing_enter'] = 'Press E to enter',
    ['housing_exit'] = 'Press E to exit',
    ['housing_locked'] = 'Property is locked',
    ['housing_unlocked'] = 'Property unlocked',
    ['housing_no_access'] = 'You don\'t have access',
    ['housing_purchased'] = 'Property purchased',
    ['housing_sold'] = 'Property sold',
    ['housing_rent_paid'] = 'Rent paid: $%s',
    ['housing_rent_due'] = 'Rent due: $%s',

    -- Missions
    ['mission_started'] = 'Mission started: %s',
    ['mission_completed'] = 'Mission completed!',
    ['mission_failed'] = 'Mission failed',
    ['mission_abandoned'] = 'Mission abandoned',
    ['mission_objective'] = 'Objective: %s',
    ['mission_reward'] = 'Reward: $%s',
    ['mission_on_cooldown'] = 'Mission on cooldown',

    -- Admin
    ['admin_no_permission'] = 'You don\'t have permission',
    ['admin_player_not_found'] = 'Player not found',
    ['admin_teleported'] = 'You have been teleported',
    ['admin_kicked'] = 'Player kicked',
    ['admin_banned'] = 'Player banned',
    ['admin_unbanned'] = 'Player unbanned',
    ['admin_frozen'] = 'Player frozen',
    ['admin_unfrozen'] = 'Player unfrozen',

    -- Errors
    ['error_generic'] = 'An error occurred',
    ['error_not_found'] = 'Not found',
    ['error_invalid'] = 'Invalid input',
    ['error_timeout'] = 'Request timed out',
    ['error_cooldown'] = 'Please wait before trying again',
    ['error_restricted'] = 'This action is restricted',

    -- Time
    ['time_seconds'] = '%s seconds',
    ['time_minutes'] = '%s minutes',
    ['time_hours'] = '%s hours',
    ['time_days'] = '%s days',
}

return AIT.Locales.en
