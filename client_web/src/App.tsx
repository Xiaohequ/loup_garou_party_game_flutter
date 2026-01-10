import { Lobby } from '@/components/Lobby'
import { RoleReveal } from '@/components/RoleReveal'
import { NightView } from '@/components/NightView'
import { DayView } from '@/components/DayView'
import { VoteView } from '@/components/VoteView'
import { VoteResultView } from '@/components/VoteResultView'
import { HunterView } from '@/components/HunterView'

import { useGameSocket } from '@/hooks/useGameSocket'
import { GamePhase, GameWinner } from '@/types';


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


    // Transition State (Fermer les yeux)
    if (gameState.isTransitioning) {
        return (
            <div className="flex flex-col items-center justify-center min-h-screen bg-black text-white p-4 text-center z-50 fixed inset-0">
                <h1 className="text-4xl md:text-6xl font-black mb-8 animate-pulse text-red-600">FERMER LES YEUX</h1>
                <div className="text-8xl font-bold bg-white/10 rounded-full h-32 w-32 flex items-center justify-center border-4 border-white/20">
                    {gameState.countdown}
                </div>
                <p className="mt-8 text-xl text-slate-400 italic">La nuit continue...</p>
            </div>
        );
    }


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



    // Phase: Hunter Revenge
    if (gameState.phase === GamePhase.hunterRevenge && myPlayer) {
        return <HunterView gameState={gameState} myPlayer={myPlayer} onAction={sendAction} />;
    }

    // Phase: End
    if (gameState.phase === GamePhase.end) {
        let title = "FIN DE PARTIE";
        let color = "text-yellow-500";
        if (gameState.winner === GameWinner.villagers) {
            title = "VICTOIRE DES VILLAGEOIS";
            color = "text-green-500";
        } else if (gameState.winner === GameWinner.werewolves) {
            title = "VICTOIRE DES LOUPS";
            color = "text-red-600";
        }

        return (
            <div className="flex flex-col items-center justify-center min-h-screen bg-slate-900 text-white p-4 text-center">
                <h1 className={`text-5xl md:text-6xl font-black mb-6 ${color}`}>{title}</h1>
                <div className="p-6 bg-slate-800 rounded-lg w-full max-w-md">
                    <p className="text-xl mb-4 font-semibold text-slate-300">Les Survivants :</p>
                    <ul className="mb-6 space-y-2">
                        {gameState.players.filter(p => p.isAlive).map(p => (
                            <li key={p.id} className="text-2xl font-bold bg-slate-700 p-2 rounded flex justify-between items-center">
                                <span>{p.name}</span>
                                <span className="text-sm font-normal text-slate-400">({p.role})</span>
                            </li>
                        ))}
                    </ul>
                    {gameState.players.filter(p => p.isAlive).length === 0 && (
                        <p className="text-slate-500 italic mb-6">Aucun survivant...</p>
                    )}
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
