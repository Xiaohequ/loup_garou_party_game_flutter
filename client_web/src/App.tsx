import { Lobby } from '@/components/Lobby'
import { RoleReveal } from '@/components/RoleReveal'
import { NightView } from '@/components/NightView'
import { useGameSocket } from '@/hooks/useGameSocket'
import { GamePhase } from '@/types';


function App() {
    const { gameState, isConnected, joinGame, setReady, sendAction, playerId } = useGameSocket();

    const myPlayerId = playerId;

    // Loading State
    if (!gameState) {
        return <Lobby
            onJoin={joinGame}
            onReady={setReady}
            isConnected={isConnected}
            players={[]}
            myPlayerId={myPlayerId}
        />;
    }

    const myPlayer = gameState.players.find(p => p.id === myPlayerId);

    // Phase: Lobby
    if (gameState.phase === GamePhase.lobby) {
        return <Lobby
            onJoin={joinGame}
            onReady={setReady}
            isConnected={isConnected}
            players={gameState.players}
            myPlayerId={myPlayerId}
        />;
    }

    // Phase: Role Distribution
    if (gameState.phase === GamePhase.rolesDistribution && myPlayer) {
        if (!myPlayer.isReady) {
            return <RoleReveal role={myPlayer.role} onConfirm={setReady} />;
        }
        return (
            <div className="flex flex-col items-center justify-center min-h-screen bg-slate-950 text-slate-100 p-4 text-center">
                <h2 className="text-2xl font-bold mb-4">En attente des autres joueurs...</h2>
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-white"></div>
            </div>
        );
    }

    // Phase: Night
    if (gameState.phase === GamePhase.night && myPlayer) {
        return <NightView gameState={gameState} myPlayer={myPlayer} onAction={sendAction} />;
    }

    return (
        <div className="flex flex-col items-center justify-center min-h-screen bg-background p-4">
            <h1 className="text-4xl font-bold mb-4">Phase: {gameState.phase}</h1>
            <p className="mb-4">Le jour se lève... (À suivre)</p>
            <div className="p-4 bg-slate-100 rounded w-full max-w-md">
                <h2 className="font-bold">Survivants:</h2>
                <ul>
                    {gameState.players.filter(p => p.isAlive).map(p => (
                        <li key={p.id}>{p.name}</li>
                    ))}
                </ul>
            </div>
            <div className="p-4 bg-red-100 rounded w-full max-w-md mt-4">
                <h2 className="font-bold">Morts cette nuit:</h2>
                <ul>
                    {gameState.players.filter(p => !p.isAlive).map(p => (
                        <li key={p.id}>{p.name} ({p.role})</li>
                    ))}
                </ul>
            </div>
        </div>
    )
}

export default App
