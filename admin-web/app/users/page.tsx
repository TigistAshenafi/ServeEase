'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Layout from '@/components/Layout';
import { isAuthenticated } from '@/lib/auth';
import { userAPI } from '@/lib/api';
import { User } from '@/lib/types';
import { formatDate } from '@/lib/utils';
import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell } from '@/components/ui/Table';
import Badge from '@/components/ui/Badge';
import Button from '@/components/ui/Button';
import Modal from '@/components/ui/Modal';
import Pagination from '@/components/ui/Pagination';
import toast, { Toaster } from 'react-hot-toast';
import {
  EyeIcon,
  NoSymbolIcon,
  CheckCircleIcon,
  TrashIcon,
  MagnifyingGlassIcon,
} from '@heroicons/react/24/outline';

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [showModal, setShowModal] = useState(false);
  const [actionType, setActionType] = useState<'suspend' | 'activate' | 'delete' | 'view'>('view');
  const [reason, setReason] = useState('');
  const [actionLoading, setActionLoading] = useState(false);
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [totalItems, setTotalItems] = useState(0);
  const [roleFilter, setRoleFilter] = useState('all');
  const [searchTerm, setSearchTerm] = useState('');
  const router = useRouter();

  useEffect(() => {
    if (!isAuthenticated()) {
      router.push('/login');
      return;
    }

    fetchUsers();
  }, [router, currentPage, roleFilter]);

  const fetchUsers = async () => {
    try {
      setLoading(true);
      const response = await userAPI.getAll({
        page: currentPage,
        limit: 10,
        role: roleFilter === 'all' ? undefined : roleFilter,
      });
      
      setUsers(response.data.users);
      setTotalPages(response.data.pagination.pages);
      setTotalItems(response.data.pagination.total);
    } catch (error) {
      toast.error('Failed to load users');
      console.error('Users fetch error:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleAction = async () => {
    if (!selectedUser) return;

    try {
      setActionLoading(true);
      
      switch (actionType) {
        case 'suspend':
          await userAPI.suspend(selectedUser.id, reason);
          toast.success('User suspended successfully');
          break;
        case 'activate':
          await userAPI.activate(selectedUser.id);
          toast.success('User activated successfully');
          break;
        case 'delete':
          await userAPI.delete(selectedUser.id);
          toast.success('User deleted successfully');
          break;
      }
      
      setShowModal(false);
      setSelectedUser(null);
      setReason('');
      fetchUsers();
    } catch (error) {
      toast.error(`Failed to ${actionType} user`);
      console.error(`User ${actionType} error:`, error);
    } finally {
      setActionLoading(false);
    }
  };

  const openModal = (user: User, type: 'suspend' | 'activate' | 'delete' | 'view') => {
    setSelectedUser(user);
    setActionType(type);
    setReason('');
    setShowModal(true);
  };

  const closeModal = () => {
    setShowModal(false);
    setSelectedUser(null);
    setReason('');
  };

  const filteredUsers = users.filter(user =>
    user.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    user.email.toLowerCase().includes(searchTerm.toLowerCase())
  );

  if (loading) {
    return (
      <Layout>
        <div className="flex items-center justify-center h-64">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
        </div>
      </Layout>
    );
  }

  return (
    <Layout>
      <Toaster position="top-right" />
      <div className="space-y-6">
        {/* Header */}
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">User Management</h1>
            <p className="mt-1 text-sm text-gray-500">
              Manage platform users and their access
            </p>
          </div>
        </div>

        {/* Filters and Search */}
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="flex-1">
            <div className="relative">
              <MagnifyingGlassIcon className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
              <input
                type="text"
                placeholder="Search users..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10 form-input"
              />
            </div>
          </div>
          <select
            value={roleFilter}
            onChange={(e) => {
              setRoleFilter(e.target.value);
              setCurrentPage(1);
            }}
            className="form-select"
          >
            <option value="all">All Roles</option>
            <option value="seeker">Seekers</option>
            <option value="provider">Providers</option>
            <option value="admin">Admins</option>
          </select>
        </div>

        {/* Users Table */}
        <div className="card">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>User</TableHead>
                <TableHead>Role</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Email Verified</TableHead>
                <TableHead>Joined</TableHead>
                <TableHead>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredUsers.map((user) => (
                <TableRow key={user.id}>
                  <TableCell>
                    <div>
                      <div className="font-medium text-gray-900">{user.name}</div>
                      <div className="text-gray-500">{user.email}</div>
                    </div>
                  </TableCell>
                  <TableCell>
                    <Badge status={user.role}>
                      {user.role}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <Badge status={user.isActive === false ? 'suspended' : 'active'}>
                      {user.isActive === false ? 'Suspended' : 'Active'}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <Badge status={user.emailVerified ? 'approved' : 'pending'}>
                      {user.emailVerified ? 'Verified' : 'Unverified'}
                    </Badge>
                  </TableCell>
                  <TableCell>{formatDate(user.createdAt)}</TableCell>
                  <TableCell>
                    <div className="flex space-x-2">
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => openModal(user, 'view')}
                      >
                        <EyeIcon className="h-4 w-4" />
                      </Button>
                      {user.role !== 'admin' && (
                        <>
                          {user.isActive !== false ? (
                            <Button
                              size="sm"
                              variant="danger"
                              onClick={() => openModal(user, 'suspend')}
                            >
                              <NoSymbolIcon className="h-4 w-4" />
                            </Button>
                          ) : (
                            <Button
                              size="sm"
                              variant="success"
                              onClick={() => openModal(user, 'activate')}
                            >
                              <CheckCircleIcon className="h-4 w-4" />
                            </Button>
                          )}
                          <Button
                            size="sm"
                            variant="danger"
                            onClick={() => openModal(user, 'delete')}
                          >
                            <TrashIcon className="h-4 w-4" />
                          </Button>
                        </>
                      )}
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>

          {filteredUsers.length === 0 && (
            <div className="text-center py-12">
              <p className="text-gray-500">No users found</p>
            </div>
          )}

          <Pagination
            currentPage={currentPage}
            totalPages={totalPages}
            onPageChange={setCurrentPage}
            totalItems={totalItems}
            itemsPerPage={10}
          />
        </div>
      </div>

      {/* User Details Modal */}
      <Modal
        isOpen={showModal}
        onClose={closeModal}
        title={
          actionType === 'view' 
            ? 'User Details' 
            : actionType === 'suspend'
            ? 'Suspend User'
            : actionType === 'activate'
            ? 'Activate User'
            : 'Delete User'
        }
        size="lg"
      >
        {selectedUser && (
          <div className="space-y-6">
            {/* User Info */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700">Name</label>
                <p className="mt-1 text-sm text-gray-900">{selectedUser.name}</p>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">Email</label>
                <p className="mt-1 text-sm text-gray-900">{selectedUser.email}</p>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">Role</label>
                <p className="mt-1 text-sm text-gray-900 capitalize">{selectedUser.role}</p>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">Status</label>
                <p className="mt-1 text-sm text-gray-900">
                  {selectedUser.isActive === false ? 'Suspended' : 'Active'}
                </p>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">Email Verified</label>
                <p className="mt-1 text-sm text-gray-900">
                  {selectedUser.emailVerified ? 'Yes' : 'No'}
                </p>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">Joined</label>
                <p className="mt-1 text-sm text-gray-900">{formatDate(selectedUser.createdAt)}</p>
              </div>
            </div>

            {/* Suspension Info */}
            {selectedUser.suspendedAt && (
              <div>
                <label className="block text-sm font-medium text-gray-700">Suspended</label>
                <p className="mt-1 text-sm text-gray-900">{formatDate(selectedUser.suspendedAt)}</p>
                {selectedUser.suspensionReason && (
                  <div className="mt-2">
                    <label className="block text-sm font-medium text-gray-700">Reason</label>
                    <p className="mt-1 text-sm text-gray-900 p-3 bg-gray-50 rounded">
                      {selectedUser.suspensionReason}
                    </p>
                  </div>
                )}
              </div>
            )}

            {/* Action-specific content */}
            {actionType === 'suspend' && (
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Reason for Suspension <span className="text-red-500">*</span>
                </label>
                <textarea
                  value={reason}
                  onChange={(e) => setReason(e.target.value)}
                  rows={3}
                  className="mt-1 form-textarea"
                  placeholder="Please provide a reason for suspending this user..."
                  required
                />
              </div>
            )}

            {actionType === 'delete' && (
              <div className="bg-red-50 border border-red-200 rounded-md p-4">
                <div className="flex">
                  <div className="ml-3">
                    <h3 className="text-sm font-medium text-red-800">
                      Warning: This action cannot be undone
                    </h3>
                    <div className="mt-2 text-sm text-red-700">
                      <p>
                        Deleting this user will permanently remove their account and all associated data.
                        This includes their profile, service requests, and any other platform activity.
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {actionType === 'activate' && selectedUser.suspensionReason && (
              <div className="bg-blue-50 border border-blue-200 rounded-md p-4">
                <div className="flex">
                  <div className="ml-3">
                    <h3 className="text-sm font-medium text-blue-800">
                      Previous Suspension Reason
                    </h3>
                    <div className="mt-2 text-sm text-blue-700">
                      <p>{selectedUser.suspensionReason}</p>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Actions */}
            {actionType !== 'view' && (
              <div className="flex justify-end space-x-3">
                <Button variant="outline" onClick={closeModal}>
                  Cancel
                </Button>
                <Button
                  variant={actionType === 'activate' ? 'success' : 'danger'}
                  onClick={handleAction}
                  loading={actionLoading}
                  disabled={actionType === 'suspend' && !reason.trim()}
                >
                  {actionType === 'suspend' && 'Suspend User'}
                  {actionType === 'activate' && 'Activate User'}
                  {actionType === 'delete' && 'Delete User'}
                </Button>
              </div>
            )}
          </div>
        )}
      </Modal>
    </Layout>
  );
}