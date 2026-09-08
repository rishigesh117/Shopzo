import { Router } from 'express';
import { MemberController } from '../controllers/memberController';
import { authenticateToken } from '../middleware/auth';
import { authorizeShopAccess } from '../middleware/authorize';

const router = Router();

router.use(authenticateToken);

// Employee join request via shop code
router.post('/request-join', MemberController.requestJoin);
router.get('/my-requests', MemberController.listUserRequests);

// Employee pending invitations
router.get('/my-invitations', MemberController.listUserInvitations);
router.post('/invitations/:invitationId/accept', MemberController.acceptInvitation);
router.post('/invitations/:invitationId/decline', MemberController.declineInvitation);

// Owner routes (require shop header or query/param and owner/manage_members permission)
router.get('/requests', authorizeShopAccess({ permission: 'can_manage_members' }), MemberController.listShopRequests);
router.post('/requests/:requestId/accept', authorizeShopAccess({ permission: 'can_manage_members' }), MemberController.acceptRequest);
router.post('/requests/:requestId/reject', authorizeShopAccess({ permission: 'can_manage_members' }), MemberController.rejectRequest);

router.post('/invite', authorizeShopAccess({ permission: 'can_manage_members' }), MemberController.inviteMember);
router.post('/invitations/:invitationId/cancel', authorizeShopAccess({ permission: 'can_manage_members' }), MemberController.cancelInvitation);

router.get('/', authorizeShopAccess(), MemberController.listMembers);
router.put('/:targetUserId/permissions', authorizeShopAccess({ requireOwner: true }), MemberController.updatePermissions);
router.delete('/:targetUserId', authorizeShopAccess({ requireOwner: true }), MemberController.removeMember);

export default router;
