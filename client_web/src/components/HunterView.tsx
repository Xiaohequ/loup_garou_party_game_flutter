import { ActionPayload, GameState, Player } from "@/types";
import { Timer } from "lucide-react";

interface HunterViewProps {
    gameState: GameState;
    myPlayer: Player;
    onAction: (type: string, payload: ActionPayload) => void;
}

export function HunterView({ gameState, myPlayer, onAction }: HunterViewProps) {
    const isHunter = myPlayer.role === 'hunter';
    // Hunter logic: if this player is the hunter (and just died), they are the one acting.
    // However, logic says Hunter triggers revenge if killed by wolves.
    // The GameController transitions to 'hunterRevenge' ONLY if Hunter matches the victim.
    // So if we are in this phase, and I am the hunter, I can shoot.

    // BUT: My isAlive is likely false now in the state (killed at night).
    // So I am a dead hunter in this phase.

    // Let's filter players to shoot (Alive players)
    const targets = gameState.players.filter(p => p.isAlive);

    const handleShoot = (targetId: string) => {
        onAction('HUNTER_SHOT', { targetId });
    };

    if (isHunter) {
        return (
            <div className="flex flex-col items-center justify-center min-h-screen bg-red-950 text-white p-4">
                <div className="max-w-md w-full text-center">
                    <h1 className="text-4xl font-bold mb-4 text-red-500">VENGEANCE !</h1>
                    <p className="text-xl mb-6">
                        Les Loups-Garous vous ont eu... mais vous avez encore un dernier souffle.
                        <br />
                        <span className="font-bold text-yellow-400">Tirez sur quelqu'un pour l'emmener avec vous !</span>
                    </p>

                    <div className="grid grid-cols-2 gap-4">
                        {targets.map(player => (
                            <button
                                key={player.id}
                                onClick={() => handleShoot(player.id)}
                                className="bg-slate-800 p-4 rounded-lg border-2 border-slate-600 hover:border-red-500 transition-colors flex flex-col items-center"
                            >
                                <span className="text-2xl mb-1">🎯</span>
                                <span className="font-bold">{player.name}</span>
                            </button>
                        ))}
                    </div>
                </div>
            </div>
        );
    }

    return (
        <div className="flex flex-col items-center justify-center min-h-screen bg-slate-900 text-white p-4 text-center">
            <Timer className="w-16 h-16 text-red-500 mb-4 animate-pulse" />
            <h2 className="text-2xl font-bold mb-2">COUP DE FEU IMMINENT !</h2>
            <p className="text-slate-400">
                Le Chasseur a été tué par les Loups...<br />
                Il va tirer sa dernière balle.
            </p>
        </div>
    );
}
