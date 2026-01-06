import { useState, useEffect, useCallback } from 'react';
import useWebSocket, { ReadyState } from 'react-use-websocket';
import { GameState, ClientMessage } from '../types';

export const useGameSocket = () => {
    const [gameState, setGameState] = useState<GameState | null>(null);
    const [playerId, setPlayerId] = useState<string | null>(sessionStorage.getItem('playerId'));

    const protocol = window.location.protocol === 'https:' ? 'wss' : 'ws';
    const host = window.location.host;
    const wsUrl = `${protocol}://${host}/ws`;

    // Use a ref to prevent reconnection loops in some edge cases with strict mode
    const { sendMessage, lastMessage, readyState } = useWebSocket(wsUrl, {
        shouldReconnect: () => true,
        reconnectInterval: 3000,
    });

    useEffect(() => {
        if (lastMessage !== null) {
            try {
                const data = JSON.parse(lastMessage.data);
                if (data.type === 'STATE_UPDATE') {
                    setGameState(data.state);

                    // Check if we were kicked/reset
                    const currentId = sessionStorage.getItem('playerId');
                    if (currentId && data.state.players) {
                        const me = data.state.players.find((p: any) => p.id === currentId);
                        if (!me) {
                            // We are not in the player list anymore => Reset local state
                            sessionStorage.removeItem('playerId');
                            sessionStorage.removeItem('playerName');
                            setPlayerId(null);
                        }
                    }

                } else if (data.type === 'PLAYER_INFO') {
                    const newId = data.payload.id;
                    const newName = data.payload.name;
                    sessionStorage.setItem('playerId', newId);
                    sessionStorage.setItem('playerName', newName);
                    setPlayerId(newId);
                    console.log("Joined as", data.payload);
                }
            } catch (e) {
                console.error("Failed to parse WS message", e);
            }
        }
    }, [lastMessage]);

    const sendClientMessage = useCallback((msg: ClientMessage) => {
        sendMessage(JSON.stringify(msg));
    }, [sendMessage]);

    const joinGame = (name: string) => {
        sendClientMessage({ type: 'JOIN', payload: { name } });
    };

    const setReady = () => {
        // Use state or session
        const pid = playerId || sessionStorage.getItem('playerId');
        if (pid) {
            sendClientMessage({ type: 'READY', payload: { playerId: pid } });
        }
    };

    const sendAction = (type: string, payload: any) => {
        const pid = playerId || sessionStorage.getItem('playerId');
        if (pid) {
            sendClientMessage({
                type: 'ACTION',
                payload: {
                    playerId: pid,
                    actionType: type,
                    ...payload
                }
            });
        }
    };

    return {
        gameState,
        playerId,
        readyState,
        isConnected: readyState === ReadyState.OPEN,
        joinGame,
        setReady,
        sendAction,
    };
};
