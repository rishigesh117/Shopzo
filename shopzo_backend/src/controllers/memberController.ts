import { Response } from 'express';
import { AuthenticatedRequest } from '../middleware/auth';
import { ShopRepository } from '../repositories/shopRepository';
import { MemberRepository } from '../repositories/memberRepository';
import { RequestRepository } from '../repositories/requestRepository';
import { InvitationRepository } from '../repositories/invitationRepository';
import { UserRepository } from '../repositories/userRepository';

export class MemberController {
  // Employee -> Owner: Join request using Shop Code
  static async requestJoin(req: AuthenticatedRequest, res: Response) {
    try {
      const userId = req.user?.userId;
      const { shopCode } = req.body;

      if (!userId) {
        return res.status(401).json({ success: false, error: 'Unauthorized' });
      }

      if (!shopCode) {
        return res.status(400).json({ success: false, error: 'Shop code required' });
      }

      const shop = await ShopRepository.findByCode(shopCode.trim().toUpperCase());
      if (!shop) {
        return res.status(404).json({ success: false, error: 'Invalid Shop Code' });
      }

      // Check if already a member
      const existingMember = await MemberRepository.findMember(shop.id, userId);
      if (existingMember && existingMember.status === 'ACTIVE') {
        return res.status(400).json({ success: false, error: 'You are already an active member of this shop' });
      }

      const joinReq = await RequestRepository.createRequest(shop.id, userId);
      return res.status(201).json({
        success: true,
        data: {
          ...joinReq,
          shop_name: shop.name,
          shop_code: shop.shop_code
        }
      });
    } catch (error: any) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  // Owner -> Employee: Invitation using Phone Number
  static async inviteMember(req: AuthenticatedRequest, res: Response) {
    try {
      const userId = req.user?.userId;
      const shopId = req.shopMember?.shopId;
      const { phone, permissions } = req.body;

      if (!userId || !shopId) {
        return res.status(400).json({ success: false, error: 'User and Shop context required' });
      }

      if (!phone) {
        return res.status(400).json({ success: false, error: 'Employee phone number required' });
      }

      // Check if target user is already an active member
      const targetUser = await UserRepository.findByPhone(phone);
      if (targetUser) {
        const existingMember = await MemberRepository.findMember(shopId, targetUser.id);
        if (existingMember && existingMember.status === 'ACTIVE') {
          return res.status(400).json({ success: false, error: 'User is already an active member of this shop' });
        }
      }

      const permissionsJson = permissions ? JSON.stringify(permissions) : undefined;
      const invitation = await InvitationRepository.createInvitation(shopId, phone, userId, permissionsJson);

      return res.status(201).json({
        success: true,
        data: invitation
      });
    } catch (error: any) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  // Owner: List join requests for shop
  static async listShopRequests(req: AuthenticatedRequest, res: Response) {
    try {
      const shopId = req.shopMember?.shopId;
      if (!shopId) return res.status(400).json({ success: false, error: 'Shop ID required' });

      const requests = await RequestRepository.listShopRequests(shopId);
      return res.json({ success: true, data: requests });
    } catch (error: any) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  // Employee: List sent join requests
  static async listUserRequests(req: AuthenticatedRequest, res: Response) {
    try {
      const userId = req.user?.userId;
      if (!userId) return res.status(401).json({ success: false, error: 'Unauthorized' });

      const requests = await RequestRepository.listUserRequests(userId);
      return res.json({ success: true, data: requests });
    } catch (error: any) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  // Owner: Accept join request
  static async acceptRequest(req: AuthenticatedRequest, res: Response) {
    try {
      const { requestId } = req.params;
      const { permissions } = req.body; // Optional custom permissions

      const request = await RequestRepository.findById(requestId);
      if (!request || request.status !== 'PENDING') {
        return res.status(400).json({ success: false, error: 'Invalid or non-pending request' });
      }

      // Add user as member
      const member = await MemberRepository.addMember(request.shop_id, request.user_id, 'EMPLOYEE');
      // Set permissions (default: full access or custom)
      const permData = permissions || { is_full_access: true };
      await MemberRepository.setPermissions(request.shop_id, request.user_id, permData);

      const updatedRequest = await RequestRepository.updateStatus(requestId, 'ACCEPTED');
      return res.json({ success: true, data: { request: updatedRequest, member } });
    } catch (error: any) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  // Owner: Reject join request
  static async rejectRequest(req: AuthenticatedRequest, res: Response) {
    try {
      const { requestId } = req.params;
      const request = await RequestRepository.findById(requestId);
      if (!request || request.status !== 'PENDING') {
        return res.status(400).json({ success: false, error: 'Invalid or non-pending request' });
      }

      const updatedRequest = await RequestRepository.updateStatus(requestId, 'REJECTED');
      return res.json({ success: true, data: updatedRequest });
    } catch (error: any) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  // Employee: List pending invitations received
  static async listUserInvitations(req: AuthenticatedRequest, res: Response) {
    try {
      const phone = req.user?.phone;
      if (!phone) return res.status(401).json({ success: false, error: 'Unauthorized' });

      const invitations = await InvitationRepository.listUserInvitations(phone);
      return res.json({ success: true, data: invitations });
    } catch (error: any) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  // Employee: Accept invitation
  static async acceptInvitation(req: AuthenticatedRequest, res: Response) {
    try {
      const userId = req.user?.userId;
      const phone = req.user?.phone;
      const { invitationId } = req.params;

      if (!userId || !phone) return res.status(401).json({ success: false, error: 'Unauthorized' });

      const invitation = await InvitationRepository.findById(invitationId);
      if (!invitation || invitation.status !== 'PENDING' || invitation.phone !== phone) {
        return res.status(400).json({ success: false, error: 'Invalid or non-pending invitation' });
      }

      // Add user as member
      const member = await MemberRepository.addMember(invitation.shop_id, userId, 'EMPLOYEE');

      // Set permissions from invitation
      let permData = { is_full_access: true };
      if (invitation.permissions_json) {
        try {
          permData = JSON.parse(invitation.permissions_json);
        } catch (e) {}
      }
      await MemberRepository.setPermissions(invitation.shop_id, userId, permData);

      const updatedInvitation = await InvitationRepository.updateStatus(invitationId, 'ACCEPTED');
      return res.json({ success: true, data: { invitation: updatedInvitation, member } });
    } catch (error: any) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  // Employee: Decline invitation
  static async declineInvitation(req: AuthenticatedRequest, res: Response) {
    try {
      const phone = req.user?.phone;
      const { invitationId } = req.params;

      const invitation = await InvitationRepository.findById(invitationId);
      if (!invitation || invitation.status !== 'PENDING' || invitation.phone !== phone) {
        return res.status(400).json({ success: false, error: 'Invalid or non-pending invitation' });
      }

      const updatedInvitation = await InvitationRepository.updateStatus(invitationId, 'DECLINED');
      return res.json({ success: true, data: updatedInvitation });
    } catch (error: any) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  // Owner: Cancel invitation
  static async cancelInvitation(req: AuthenticatedRequest, res: Response) {
    try {
      const { invitationId } = req.params;
      const invitation = await InvitationRepository.findById(invitationId);
      if (!invitation || invitation.status !== 'PENDING') {
        return res.status(400).json({ success: false, error: 'Invalid or non-pending invitation' });
      }

      const updatedInvitation = await InvitationRepository.updateStatus(invitationId, 'CANCELLED');
      return res.json({ success: true, data: updatedInvitation });
    } catch (error: any) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  // List shop members
  static async listMembers(req: AuthenticatedRequest, res: Response) {
    try {
      const shopId = req.shopMember?.shopId;
      if (!shopId) return res.status(400).json({ success: false, error: 'Shop ID required' });

      const members = await MemberRepository.listShopMembers(shopId);
      return res.json({ success: true, data: members });
    } catch (error: any) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  // Update member permissions (Owner only)
  static async updatePermissions(req: AuthenticatedRequest, res: Response) {
    try {
      const shopId = req.shopMember?.shopId;
      const { targetUserId } = req.params;
      const { permissions } = req.body;

      if (!shopId) return res.status(400).json({ success: false, error: 'Shop ID required' });

      const targetMember = await MemberRepository.findMember(shopId, targetUserId);
      if (!targetMember) {
        return res.status(404).json({ success: false, error: 'Member not found' });
      }

      // Owner Protection Guard
      if (targetMember.role === 'OWNER') {
        return res.status(403).json({ success: false, error: 'Cannot modify Owner permissions' });
      }

      const updatedPerms = await MemberRepository.setPermissions(shopId, targetUserId, permissions);
      return res.json({ success: true, data: updatedPerms });
    } catch (error: any) {
      return res.status(500).json({ success: false, error: error.message });
    }
  }

  // Remove member (Owner only)
  static async removeMember(req: AuthenticatedRequest, res: Response) {
    try {
      const shopId = req.shopMember?.shopId;
      const { targetUserId } = req.params;

      if (!shopId) return res.status(400).json({ success: false, error: 'Shop ID required' });

      await MemberRepository.removeMember(shopId, targetUserId);
      return res.json({ success: true, message: 'Member removed successfully' });
    } catch (error: any) {
      return res.status(400).json({ success: false, error: error.message });
    }
  }
}
