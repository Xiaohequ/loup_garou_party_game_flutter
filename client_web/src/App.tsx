import { Lobby } from '@/components/Lobby'
import { RoleReveal } from '@/components/RoleReveal'
import { NightView } from '@/components/NightView'
import { DayView } from '@/components/DayView'
import { VoteView } from '@/components/VoteView'
import { VoteResultView } from '@/components/VoteResultView'

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

    // Phase: Day
    if (gameState.phase === GamePhase.day && myPlayer) {
        return <DayView gameState={gameState} myPlayer={myPlayer} onAction={sendAction} />;
    }

    // Phase: Vote
    if (gameState.phase === GamePhase.vote && myPlayer) {
        return <VoteView gameState={gameState} myPlayer={myPlayer} onAction={sendAction} />;
    }

    // Phase: Vote Result
    if (gameState.phase === GamePhase.voteResult && myPlayer) {
        return <VoteResultView gameState={gameState} myPlayer={myPlayer} onAction={sendAction} />;
    }



    // Phase: End
    if (gameState.phase === GamePhase.end) {
        return (
            <div className="flex flex-col items-center justify-center min-h-screen bg-slate-900 text-white p-4 text-center">
                <h1 className="text-6xl font-black mb-6 text-yellow-500">FIN DE PARTIE</h1>
                <div className="p-6 bg-slate-800 rounded-lg">
                    <p className="text-xl mb-4">Les Survivants :</p>
                    <ul className="mb-6">
                        {gameState.players.filter(p => p.isAlive).map(p => (
                            <li key={p.id} className="text-2xl font-bold">{p.name} ({p.role})</li>
                        ))}
                    </ul>
                    <p className="text-sm text-slate-400">Merci d'avoir joué !</p>
                </div>
            </div>
        )
    }

    return (
        <div className="flex flex-col items-center justify-center min-h-screen bg-background p-4">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-slate-900"></div>
        </div>
    )
}

export default App
