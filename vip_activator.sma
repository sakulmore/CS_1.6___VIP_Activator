#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <colorchat>
#include <fun>
#include <fvault>

#define TASK_FLAGS 150

new g_iPlayerTime[ 33 ]
new g_szPlayerFlags[ 33 ][ 32 ]
new g_iUID[ 33 ]

new const VipsVault[] = "Vip_Vault";

public plugin_init()
{
    register_plugin( "VIP Activator", "1.0", "sakulmore" )

    register_concmd( "ray_vip", "give_vip" )
    set_task( 1.0, "check_admins", .flags = "b" )
    //register_clcmd( "say /ch", "it" )
}
public check_admins()
{
    for( new i = 1; i <= get_maxplayers(); i++ )
    {
        if( !is_user_connected( i ) )
            continue

        if( g_iPlayerTime[ i ] <= get_systime() && g_iPlayerTime[ i ] > 0 )
        {
            notify( i + TASK_FLAGS )
        }
    }
}
public client_putinserver( id )
{
    g_iPlayerTime[ id ] = -1
    g_iUID[ id ] = get_user_userid( id )
    load_his_vip( id )
}
public give_vip( id )
{
    if( !( get_user_flags( id ) & ADMIN_MENU ) )
    {
        client_print( id, print_console, "You dont have access." )
        return PLUGIN_HANDLED
    }
    new arg[ 4 ][ 40 ], player
    read_argv( 1, arg[ 0 ], charsmax( arg[] ) )
    if( arg[ 0 ][ 0 ] )
    {
        if( containi( arg[ 0 ], "STEAM:" ) != -1 )
            player = cmd_target( id, arg[ 0 ], 8 )
        else if( equal( arg[ 0 ][ 0 ], "#" ) )
            player = cmd_target( id, arg[ 0 ], 8 )
        else
            player = cmd_target( id, arg[ 0 ], 8 )
    }
    read_argv( 2, arg[ 1 ], charsmax( arg[] ) ) //flags
    read_argv( 3, arg[ 2 ], charsmax( arg[] ) ) //add/remove
    read_argv( 4, arg[ 3 ], charsmax( arg[] ) ) //time
    new times = str_to_num( arg[ 3 ] )

    if( player )
    {
        if( equal( arg[ 2 ], "add" ) )
        {
            if( g_szPlayerFlags[ id ][ 0 ] )
                formatex( g_szPlayerFlags[ id ], charsmax( g_szPlayerFlags ), "%s%s", g_szPlayerFlags[ id ], arg[ 1 ] )
            else
                formatex( g_szPlayerFlags[ player ], charsmax( g_szPlayerFlags[] ), arg[ 1 ] )

            ColorChat( player, BLUE, "^4[Vips]^1 Admin just gave you:^3 %s^1 flag(s)!", arg[ 1 ] )
            set_task( float( get_systime() + times ), "notify", player + TASK_FLAGS )
            g_iPlayerTime[ player ] = get_systime() + times

            save_his_vip( player )
            set_user_flags( id, read_flags( g_szPlayerFlags[ id ] ) )
        }
        else if( equal( arg[ 2 ], "remove" ) )
        {
            remove_task( id + TASK_FLAGS )
            notify( id + TASK_FLAGS )
        }
    }

    return PLUGIN_HANDLED
}
public notify( task )
{
    new id = task - TASK_FLAGS
    ColorChat( id, BLUE, "^4[Vips]^1 Your flag(s):^3 %s^1 has ended!", g_szPlayerFlags[ id ] )
    new sid[ 35 ]
    get_user_authid( id, sid, charsmax( sid ) )
    remove_user_flags( id, read_flags( g_szPlayerFlags[ id ] ) )
    g_iPlayerTime[ id ] = -1
    g_szPlayerFlags[ id ][ 0 ] = EOS
    fvault_remove_key( VipsVault, sid )
}
public save_his_vip( id )
{
    new sid[ 35 ]
    get_user_authid( id, sid, charsmax( sid ) )

    if( g_iUID[ id ] != get_user_userid( id ) )
        return

    if( ( !equal( sid, "STEAM_", 6 ) ) )
        return

    new szBuffer[ 56 ]
    formatex( szBuffer, charsmax( szBuffer ), "%s %d %d", g_szPlayerFlags[ id ], get_systime(), g_iPlayerTime[ id ] )
    fvault_pset_data( VipsVault, sid, szBuffer )
}
public load_his_vip( id )
{
    new szAuthId[35];
    get_user_authid( id, szAuthId, charsmax( szAuthId ) )

    if( !szAuthId[0] || (!equal(szAuthId, "STEAM_", 6) && !equal(szAuthId, "VALVE_", 6)) )
        return

    new szBuffer[56], data[4][15];
    if( fvault_get_data( VipsVault, szAuthId, szBuffer, charsmax( szBuffer ) ) )
    {
        if( g_iUID[ id ] == get_user_userid( id ) )
        {
            //steamid, flags, currenttime, endtime
            parse(szBuffer, data[ 0 ], charsmax( data[] ), data[ 1 ], charsmax( data[] ), data[ 2 ], charsmax( data[] ) )
            formatex( g_szPlayerFlags[ id ], charsmax( g_szPlayerFlags[] ), data[ 0 ] )
            set_user_flags( id, read_flags( g_szPlayerFlags[ id ] ) )
            g_iPlayerTime[ id ] = str_to_num( data[ 2 ] )
            ColorChat( id, BLUE, "^4[Vips]^1 Your:^3 %s^1 flag(s) loaded!", g_szPlayerFlags[ id ] )
        }
    }
}
public it( id )
    client_print( id, 3, "flags: %d time: %d - now: %d", g_szPlayerFlags[ id ], g_iPlayerTime[ id ], get_systime() )
