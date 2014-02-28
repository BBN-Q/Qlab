/*
 * BankBouncerThread.h
 *
 *  Created on: Nov 9, 2012
 *      Author: qlab
 */


#include "headings.h"

#ifndef BANKBOUNCERTHREAD_H_
#define BANKBOUNCERTHREAD_H_

class APS;

//A generic background thread runner class that must be inherited from
class Runnable
{
	//Since std::thread and std::atomic are not copyable we need to forbid copying
    Runnable( const Runnable &) = delete;
    Runnable & operator =( const Runnable &) = delete;


public:
    Runnable() : running_(), m_thread_() { }
    virtual ~Runnable() { try { stop(); } catch(...) { /*??*/ } }

    //However, we do want to allow moving to put in a vector
    Runnable(Runnable && rhs) {
    	running_ = rhs.running_.load();
    	m_thread_ = std::move(rhs.m_thread_);
    }
    Runnable& operator=(Runnable&& rhs) {
    	running_ = rhs.running_.load();
    	m_thread_ = std::move(rhs.m_thread_);
    	return *this;
    }

    void stop() {
    	if (running_) {
    		running_ = false;
    		m_thread_.join();
    	} else {
    		running_ = false;
    	}
    }
    void start() {
    	if (!running_) {
    		running_ = true;
    		m_thread_ = std::thread(&Runnable::run, this);
    	} else {
    		running_ = true;
    	}
    }

    bool isRunning() {
    	return running_;
    }

protected:
    virtual void run() = 0;
    std::atomic<bool> running_;

private:
    std::thread m_thread_;
};


class BankBouncerThread : public Runnable
{
public:
	BankBouncerThread() : channel_(), myAPS_() {};
	BankBouncerThread(int ch, APS * aps) : channel_{ch}, myAPS_{aps} {};

protected:
	void run();

private:
	int channel_;
    APS * myAPS_;
};

#endif /* BANKBOUNCERTHREAD_H_ */
