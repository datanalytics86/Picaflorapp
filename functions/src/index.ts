import { setGlobalOptions } from 'firebase-functions/v2';
import { REGION } from './https';

setGlobalOptions({ region: REGION, maxInstances: 20 });

export { updateLocation } from './updateLocation';
export { getNearby } from './getNearby';
export { sendWave, respondWave } from './waves';
export { blockUser } from './blockUser';
export { deleteAccount } from './deleteAccount';
export { exportMyData } from './exportMyData';
export { revenuecatWebhook } from './revenuecatWebhook';
export { onMessageCreated } from './onMessageCreated';
export { touchActivity } from './touchActivity';
