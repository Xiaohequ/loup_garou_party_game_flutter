export enum GamePhase {
    lobby = 'lobby',
    rolesDistribution = 'rolesDistribution',
    night = 'night',
    day = 'day',
    vote = 'vote',
    end = 'end',
}

export enum Role {
    villager = 'villager',
    werewolf = 'werewolf',
    seer = 'seer',
    witch = 'witch',
    hunter = 'hunter',
}

export enum NightSubPhase {
    none = 'none',
    werewolfTurn = 'werewolfTurn',
    seerTurn = 'seerTurn',
    witchTurn = 'witchTurn',
    hunterTurn = 'hunterTurn',
}

export interface Player {
    id: string;
    name: string;
    isAlive: boolean;
    role: Role;
    isReady: boolean;
}

export interface GameState {
    phase: GamePhase;
    subPhase: NightSubPhase;
    players: Player[];
    turnCount: number;
    votes: Record<string, string>; // VoterID -> TargetID
    witchUsedLifePotion: boolean;
    witchUsedDeathPotion: boolean;
    seerRevealedId: string | null;
    dyingPlayerIds: string[];
}

export interface PlayerInfoPayload {
    id: string;
    name: string;
}

export type ServerMessage =
    | { type: 'STATE_UPDATE'; state: GameState }
    | { type: 'PLAYER_INFO'; payload: PlayerInfoPayload };

export type ClientMessage =
    | { type: 'JOIN'; payload: { name: string } }
    | { type: 'READY'; payload: { playerId: string } }
    | { type: 'ACTION'; payload: any };
